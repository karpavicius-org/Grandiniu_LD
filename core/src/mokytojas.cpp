// MOKYTOJAS — dėstytojo vertinimo programa.
// Naudojimas:
//   mokytojas                          — įvertina ataskaitas dabartiniame aplanke
//   mokytojas <aplankas>               — įvertina ataskaitas vietiniame aplanke
//   mokytojas <Drive nuoroda arba ID>  — parsisiunčia iš Google Drive ir įvertina
// Rezultatai (ten, kur paleista):
//   IVERTINIMAI.csv   — papildomas žurnalas (dedup pagal failo turinio SHA-256)
//   atsiliepimai/     — po failą studentui su klaidų paaiškinimais
// Google Drive API raktas: env GRANDINIU_DRIVE_API_KEY arba drive_raktas.txt
// (pirma ne tuščia eilutė) darbo aplanke. Konstitucija kaip visame branduolyje:
// logika be platformos API; windows.h tik žemiau esančioje platformos sekcijoje.
#ifdef _WIN32
#define _CRT_SECURE_NO_WARNINGS
#define NOMINMAX
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <functional>
#include <mutex>
#include <thread>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>
#include "grader.hpp"

namespace fs = std::filesystem;

namespace {

// ---------------------------------------------------------------- platforma --
// curl paleidimas be shell interpretatoriaus (kaip C ABI — jokios „sh -c").
#ifdef _WIN32
std::wstring utf8_to_wide(const std::string& s) {
    if (s.empty()) return std::wstring();
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
    std::wstring w((size_t)n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], n);
    return w;
}
#endif

std::string read_file(const fs::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return std::string();
    return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

// Grąžina programos išėjimo kodą; err — stderr tekstas. argv_parts[0] — programa.
int run_prog(const std::vector<std::string>& argv_parts, const fs::path& errfile) {
#ifdef _WIN32
    std::string cmdline;
    for (const auto& a : argv_parts) { if (!cmdline.empty()) cmdline += ' '; cmdline += '\"'; cmdline += a; cmdline += '\"'; }
    STARTUPINFOW si{}; si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    SECURITY_ATTRIBUTES sa{sizeof(sa), nullptr, TRUE};
    HANDLE he = CreateFileW(errfile.wstring().c_str(), GENERIC_WRITE, FILE_SHARE_READ,
                            &sa, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, nullptr);
    if (he != INVALID_HANDLE_VALUE) { si.hStdError = he; }
    PROCESS_INFORMATION pi{};
    std::wstring w = utf8_to_wide(cmdline);
    BOOL ok = CreateProcessW(nullptr, &w[0], nullptr, nullptr, TRUE,
                             CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
    if (he != INVALID_HANDLE_VALUE && (!ok || si.hStdOutput == si.hStdError)) CloseHandle(he);
    if (!ok) return 127;
    WaitForSingleObject(pi.hProcess, 120000);
    DWORD code = 0; GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
    return (int)code;
#else
    int errfd = ::open(errfile.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (errfd < 0) return 126;
    pid_t pid = ::fork();
    if (pid == 0) {
        ::dup2(errfd, STDERR_FILENO);
        ::close(errfd);
        std::vector<char*> argv;
        for (const auto& a : argv_parts) argv.push_back(const_cast<char*>(a.c_str()));
        argv.push_back(nullptr);
        ::execvp(argv_parts[0].c_str(), argv.data());
        ::_exit(127);
    }
    ::close(errfd);
    int st = 0;
    ::waitpid(pid, &st, 0);
    return WIFEXITED(st) ? WEXITSTATUS(st) : -1;
#endif
}

// curl — kaip anksčiau, per bendrą paleidėją.
int run_curl(const std::vector<std::string>& args, const fs::path& errfile) {
    std::vector<std::string> full;
    full.push_back("curl");
    for (const auto& a : args) full.push_back(a);
    return run_prog(full, errfile);
}

long pid_value() {
#ifdef _WIN32
    return (long)GetCurrentProcessId();
#else
    return (long)getpid();
#endif
}

// ----------------------------------------------------------------- SHA-256 --
// FIPS 180-4. Savarankiška implementacija, kad priklausomybių užraktai
// (Eigen + nlohmann SHA256 pin'ai) liktų nepaliesti.
class Sha256 {
    std::uint32_t st[8];
    std::uint64_t total = 0;
    unsigned char buf[64];
    std::size_t fill = 0;
    static std::uint32_t rotr(std::uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }
    void compress(const unsigned char* p) {
        static const std::uint32_t K[64] = {
            0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
            0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
            0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
            0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
            0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
            0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
            0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
            0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
        std::uint32_t w[64];
        for (int i = 0; i < 16; ++i)
            w[i] = (std::uint32_t(p[4 * i]) << 24) | (std::uint32_t(p[4 * i + 1]) << 16)
                 | (std::uint32_t(p[4 * i + 2]) << 8) | std::uint32_t(p[4 * i + 3]);
        for (int i = 16; i < 64; ++i) {
            std::uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
            std::uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }
        std::uint32_t a = st[0], b = st[1], c = st[2], d = st[3];
        std::uint32_t e = st[4], f = st[5], g = st[6], h = st[7];
        for (int i = 0; i < 64; ++i) {
            std::uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
            std::uint32_t ch = (e & f) ^ ((~e) & g);
            std::uint32_t t1 = h + S1 + ch + K[i] + w[i];
            std::uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
            std::uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            std::uint32_t t2 = S0 + maj;
            h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
        }
        st[0] += a; st[1] += b; st[2] += c; st[3] += d;
        st[4] += e; st[5] += f; st[6] += g; st[7] += h;
    }

public:
    Sha256() : st{0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19} {}
    void update(const unsigned char* p, std::size_t n) {
        total += n;
        while (n) {
            std::size_t take = std::min(n, std::size_t(64) - fill);
            std::memcpy(buf + fill, p, take);
            fill += take; p += take; n -= take;
            if (fill == 64) { compress(buf); fill = 0; }
        }
    }
    std::string hex() {
        std::uint64_t bits = total * 8;
        unsigned char pad = 0x80;
        update(&pad, 1);
        unsigned char zero = 0;
        while (fill != 56) update(&zero, 1);
        unsigned char lenb[8];
        for (int i = 0; i < 8; ++i) lenb[i] = (unsigned char)(bits >> (56 - 8 * i));
        update(lenb, 8);
        static const char* hx = "0123456789abcdef";
        std::string out;
        out.reserve(64);
        for (int i = 0; i < 8; ++i)
            for (int j = 28; j >= 0; j -= 4) out += hx[(st[i] >> j) & 0xf];
        return out;
    }
};

bool hash_file(const fs::path& p, std::string& out) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return false;
    Sha256 h;
    std::vector<char> buf(65536);
    std::uint64_t done = 0;
    while (f) {
        f.read(buf.data(), (std::streamsize)buf.size());
        std::streamsize got = f.gcount();
        if (got > 0) { h.update((const unsigned char*)buf.data(), (size_t)got); done += (std::uint64_t)got; }
        if (done > 64ull * 1024 * 1024) return false;  // ataskaita ≤ 2 MiB; didesnė — ne mūsų
    }
    out = h.hex();
    return true;
}

// ------------------------------------------------------- CSV konvencijos ----
// Tos pačios taisyklės kaip batch.cpp suvestine.csv: UTF-8 BOM, „;“, CRLF,
// formulės įvedimo apsauga (' prieš =+-@ pradžioje), „“ citavimas.
std::string csv(std::string s) {
    auto first = s.find_first_not_of(" \t\r\n");
    if (first != std::string::npos && std::string("=+-@").find(s[first]) != std::string::npos)
        s = "'" + s;
    std::string r = "\"";
    for (char c : s) { if (c == '"') r += '"'; r += c; }
    return r + '"';
}

std::string message(const std::string& reason) {
    if (reason.find("unsupported") != std::string::npos)
        return "Nepalaikoma darbo arba ataskaitos versija. Balas neskiriamas.";
    if (reason == "variant_parameters_mismatch")
        return "Ataskaitos parametrai neatitinka priskirto variantų banko.";
    if (reason == "unsupported_file")
        return "Reikalinga stendo sukurta HTML ataskaita. Šio failo formatas nepalaikomas.";
    if (reason == "file_type")
        return "Simbolinės nuorodos ir specialūs failai neskaitomi.";
    return "Ataskaitos duomenys netinkami arba nepilni. Patikrinkite failą; jis nevertinamas nuliu.";
}

const std::vector<std::string> HEADER = {"Nr", "Data", "Studentas", "Grupė", "LD", "Variantas",
                                         "Įvertinimas", "Balai", "Iš", "Klaidos", "Failas", "SHA256"};

std::vector<std::vector<std::string>> read_csv_rows(const fs::path& p) {
    std::string data = read_file(p);
    if (data.size() >= 3 && (unsigned char)data[0] == 0xEF && (unsigned char)data[1] == 0xBB
        && (unsigned char)data[2] == 0xBF)
        data.erase(0, 3);
    std::vector<std::vector<std::string>> rows;
    std::size_t i = 0;
    while (i < data.size()) {
        std::size_t eol = data.find('\n', i);
        std::string line = data.substr(i, (eol == std::string::npos ? data.size() : eol) - i);
        i = (eol == std::string::npos) ? data.size() : eol + 1;
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) continue;
        std::vector<std::string> fields;
        std::string cur;
        bool inq = false;
        std::size_t j = 0;
        while (j < line.size()) {
            char c = line[j];
            if (inq) {
                if (c == '"') {
                    if (j + 1 < line.size() && line[j + 1] == '"') { cur += '"'; j += 2; }
                    else { inq = false; ++j; }
                } else { cur += c; ++j; }
            } else if (c == '"') { inq = true; ++j; }
            else if (c == ';') { fields.push_back(cur); cur.clear(); ++j; }
            else { cur += c; ++j; }
        }
        fields.push_back(cur);
        rows.push_back(std::move(fields));
    }
    return rows;
}

// ---------------------------------------------------------------- laikas ----
std::string now_local() {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    char b[64];
    std::snprintf(b, sizeof b, "%04d-%02d-%02d %02d:%02d", tm.tm_year + 1900, tm.tm_mon + 1,
                  tm.tm_mday, tm.tm_hour, tm.tm_min);
    return b;
}

// ----------------------------------------------------------------- Drive ----
std::string urlencode(const std::string& s) {
    static const char* hx = "0123456789ABCDEF";
    std::string r;
    for (unsigned char c : s) {
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
            || c == '-' || c == '_' || c == '.' || c == '~')
            r += (char)c;
        else { r += '%'; r += hx[c >> 4]; r += hx[c & 0xf]; }
    }
    return r;
}

bool looks_like_id(const std::string& s) {
    if (s.size() < 10 || s.size() > 120) return false;
    for (char c : s)
        if (!( (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
               || c == '-' || c == '_' ))
            return false;
    return true;
}

std::string cut_at(const std::string& s, const std::string& stops) {
    std::size_t p = s.find_first_of(stops);
    return (p == std::string::npos) ? s : s.substr(0, p);
}

std::string drive_folder_id(const std::string& arg) {
    std::size_t p = arg.find("/folders/");
    if (p != std::string::npos) return cut_at(arg.substr(p + 9), "&/?#");
    p = arg.find("id=");
    if (p != std::string::npos) return cut_at(arg.substr(p + 3), "&#");
    if (looks_like_id(arg)) return arg;
    return std::string();
}

std::string drive_key() {
    const char* env = std::getenv("GRANDINIU_DRIVE_API_KEY");
    if (env && *env) return env;
    std::ifstream f("drive_raktas.txt");
    std::string line;
    while (std::getline(f, line)) {
        std::size_t a = line.find_first_not_of(" \t\r\n\xef\xbb\xbf");
        if (a == std::string::npos) continue;
        std::size_t b = line.find_last_not_of(" \t\r\n");
        return line.substr(a, b - a + 1);
    }
    return std::string();
}

struct DriveEntry {
    std::string id, name;
};

std::string ascii_lower(std::string s) {
    for (char& c : s) if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
    return s;
}

std::vector<DriveEntry> drive_list(const std::string& folder, const std::string& key,
                                   const fs::path& tmp, int& skipped_other, int& skipped_large) {
    std::vector<DriveEntry> out;
    std::string token;
    do {
        std::string url = "https://www.googleapis.com/drive/v3/files?q="
            + urlencode("'" + folder + "' in parents and trashed = false")
            + "&fields=" + urlencode("nextPageToken,files(id,name,size,mimeType)")
            + "&pageSize=200&key=" + urlencode(key);
        if (!token.empty()) url += "&pageToken=" + urlencode(token);
        fs::path body = tmp / "sarasa.json", err = tmp / "sarasa.err";
        std::vector<std::string> args = {"-sS", "--fail", "--max-time", "60",
                                         "-o", body.string(), url};
        int rc = run_curl(args, err);
        if (rc != 0)
            throw std::runtime_error("Drive: nepavyko gauti failų sąrašo (curl=" + std::to_string(rc)
                                     + "). " + read_file(err));
        ld::Json j = ld::Json::parse(read_file(body));
        for (const auto& f : j.value("files", ld::Json::array())) {
            std::string mime = f.value("mimeType", std::string());
            if (mime.rfind("application/vnd.google-apps", 0) == 0) { ++skipped_other; continue; }
            std::string name = f.value("name", std::string());
            std::string low = ascii_lower(name);
            if (low.size() < 5 || (low.substr(low.size() - 5) != ".html"
                                   && low.substr(low.size() - 4) != ".htm")) { ++skipped_other; continue; }
            unsigned long long size = 0;
            try { size = std::stoull(f.value("size", "0")); } catch (...) { size = 0; }
            if (size > 2ull * 1024 * 1024) { ++skipped_large; continue; }
            out.push_back({f["id"].get<std::string>(), name});
        }
        token = j.value("nextPageToken", std::string());
    } while (!token.empty());
    return out;
}

fs::path drive_download(const DriveEntry& e, const std::string& key, const fs::path& tmp, int idx) {
    fs::path out = tmp / ("failas-" + std::to_string(idx) + ".html");
    fs::path err = tmp / ("failas-" + std::to_string(idx) + ".err");
    std::string url = "https://www.googleapis.com/drive/v3/files/" + e.id + "?alt=media&key="
                      + urlencode(key);
    std::vector<std::string> args = {"-sS", "--fail", "--max-time", "60",
                                     "-o", out.string(), url};
    int rc = run_curl(args, err);
    if (rc != 0)
        throw std::runtime_error("Drive: nepavyko parsisiųsti „" + e.name + "” (curl="
                                 + std::to_string(rc) + "). " + read_file(err));
    return out;
}

// ------------------------------------------------------------ vietinis sken --
std::vector<fs::path> scan_local(const fs::path& root, int& skipped_other, int& skipped_large) {
    std::vector<fs::path> out;
    std::error_code ec;
    fs::recursive_directory_iterator it(root, fs::directory_options::skip_permission_denied, ec);
    for (fs::recursive_directory_iterator end; it != end; it.increment(ec)) {
        if (ec) break;
        std::error_code lec;
        if (!it->is_regular_file(lec) || lec) continue;
        fs::path p = it->path();
        std::string ext = ascii_lower(p.extension().string());
        if (ext != ".html" && ext != ".htm") { ++skipped_other; continue; }
        if (fs::file_size(p, lec) > 2ull * 1024 * 1024 || lec) { ++skipped_large; continue; }
        out.push_back(p);
        if (out.size() >= 10000) break;
    }
    std::sort(out.begin(), out.end());
    return out;
}

// ------------------------------------------------------------ atsiliepimai --
std::string sanitize_name(const std::string& s) {
    std::string r;
    for (unsigned char c : s) {
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
            || c >= 0x80 || c == '-' || c == '_')
            r += (char)c;
        else if (c == ' ' || c == '.') r += '_';
    }
    if (r.size() > 60) r = r.substr(0, 60);
    return r;
}

std::string pretty_expected(const std::string& expected, const std::string& unit) {
    // Skaičiui — iki 6 reikšmingų skaitmenų; „choice" vienetą slepiam (komentaras paaiškina).
    if (unit == "choice") return expected;
    try {
        double d = std::stod(expected);
        char b[64];
        std::snprintf(b, sizeof b, "%.6g", d);
        return b;
    } catch (...) {
        return expected;
    }
}

void write_feedback(int nr, const std::string& display, const ld::Json& v) {
    fs::create_directories("atsiliepimai");
    char nrs[16];
    std::snprintf(nrs, sizeof nrs, "%03d", nr);
    fs::path p = fs::path("atsiliepimai")
        / (std::string(nrs) + "_" + sanitize_name(v["student"]["name"].get<std::string>()) + "_"
           + v["lab_id"].get<std::string>() + ".txt");
    std::ostringstream o;
    o << "\xef\xbb\xbf";  // BOM — Notepad draugiška
    o << "GRANDINIŲ TEORIJA — ataskaitos įvertinimas\n";
    o << "Studentas: " << v["student"]["name"].get<std::string>() << " ("
      << v["student"]["group"].get<std::string>() << ") · "
      << v["lab_id"].get<std::string>() << " · variantas " << v["variant"].get<int>() << "\n";
    o << "Data: " << now_local() << " · Failas: " << display << "\n";
    o << "Įvertinimas: " << (v["grade_10"].is_null() ? std::string("NEVERTINTA") : v["grade_10"].dump())
      << " (balai " << v["points"].dump() << " iš " << v["max_points"].dump() << ")\n\n";
    if (v["mode"] != "assessment" || v.value("practice_used", false))
        o << "MOKYMASIS: šis rezultatas neįtraukiamas į pažymių žurnalą.\n\n";
    o << "UŽDUOTYS:\n";
    for (const auto& it : v["items"]) {
        std::string status = it.value("status", std::string());
        std::string label = it.value("label", std::string());
        std::string comment = it.value("comment", std::string());
        std::string unit = it.value("unit", std::string());
        std::string expected = it.contains("expected") && !it["expected"].is_null()
                                   ? it["expected"].dump() : std::string();
        if (it.value("automatic",false)) {
            o << "[duomenys] " << label << " — " << comment;
            if (it.contains("given") && !it["given"].is_null()) o << " Rodmuo: " << it["given"].dump() << " " << unit;
            o << "\n";
        } else if (status == "correct") {
            o << "[+] " << label << "\n";
        } else if (status == "missing") {
            o << "[ ] " << label << " — atsakymas neįvestas. " << comment << "\n";
        } else if (it.contains("raw") && it["raw"].is_string()) {
            o << "[x] " << label << " — parašyta: „" << it["raw"].get<std::string>() << "”";
            if (!expected.empty())
                o << ", tikėtasi ~" << pretty_expected(expected, unit)
                  << (unit.empty() || unit == "choice" ? "" : " " + unit);
            o << ". " << comment << "\n";
        } else {
            o << "[!] " << label << " — " << comment;
            if (!expected.empty())
                o << " (tikėtasi ~" << pretty_expected(expected, unit)
                  << (unit.empty() || unit == "choice" ? "" : " " + unit) << ")";
            o << "\n";
        }
    }
    if (v.contains("note") && v["note"].is_string() && !v["note"].get<std::string>().empty())
        o << (v.value("rubric_version",std::string())=="LD1-3"?"\nProgramos pastaba: ":"\nStudento pastaba: ") << v["note"].get<std::string>() << "\n";
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    f << o.str();
}

// ------------------------------------------------------------- žurnalas ----
// Matrica „studentai × laboratoriniai" (Vardas;Grupė;LD1..LD13). Statoma iš
// IVERTINIMAI.csv žurnalo kiekvieną paleidimą iš naujo: langelyje — geriausio
// to studento ir darbo bandymo įvertinimas (didžiausi balai). Pats žurnalas
// lieka tik papildomas, todėl duomenys niekada nepradingsta.
void rebuild_zurnalas(const fs::path& journal) {
    auto rows = read_csv_rows(journal);
    struct Key {
        std::string name, group;
        bool operator<(const Key& o) const { return name != o.name ? name < o.name : group < o.group; }
    };
    std::map<Key, std::map<std::string, std::pair<double, std::string>>> best;
    for (size_t k = 1; k < rows.size(); ++k) {
        const auto& r = rows[k];
        if (r.size() != HEADER.size()) continue;
        if (r[2].empty() || r[4].empty() || r[6] == "NEVERTINTA" || r[6] == "MOKYMASIS") continue;
        double points = 0;
        try { points = std::stod(r[6]); } catch (...) { continue; }
        auto& slot = best[{r[2], r[3]}][r[4]];
        if (slot.second.empty() || slot.first < points) slot = {points, r[6]};
    }
    std::ofstream f("ZURNALAS.csv", std::ios::binary | std::ios::trunc);
    f << "\xef\xbb\xbf";
    f << csv("Vardas") << ';' << csv("Grupė");
    for (int ld = 1; ld <= 13; ++ld) f << ';' << csv("LD" + std::to_string(ld));
    f << "\r\n";
    for (const auto& entry : best) {
        f << csv(entry.first.name) << ';' << csv(entry.first.group);
        for (int ld = 1; ld <= 13; ++ld) {
            auto it = entry.second.find("LD" + std::to_string(ld));
            f << ';' << (it == entry.second.end() ? csv(std::string()) : csv(it->second.second));
        }
        f << "\r\n";
    }
}

// -------------------------------------------------------------- pagrindinė --
struct Source {
    fs::path path;
    std::string display;
};

int process(const std::vector<Source>& files, int skipped_other, int skipped_large,
            const std::function<bool(int, int)>& tick = {},
            const std::atomic<bool>* cancel = nullptr) {
    const fs::path csvp = "IVERTINIMAI.csv";
    std::set<std::string> known;
    int last_nr = 0;
    bool fresh = !fs::exists(csvp);
    if (!fresh) {
        auto rows = read_csv_rows(csvp);
        if (rows.empty()) {
            if (fs::file_size(csvp) > 0)
                throw std::runtime_error("IVERTINIMAI.csv tuščias arba neperskaitomas.");
            fresh = true;
        } else if (rows[0] != HEADER) {
            throw std::runtime_error("IVERTINIMAI.csv antraštė neatpažinta (laukiamų stulpelių nėra).");
        } else {
            for (size_t k = 1; k < rows.size(); ++k) {
                const auto& r = rows[k];
                if (r.size() == HEADER.size()) {
                    known.insert(r[11]);
                    int n = 0;
                    try { n = std::stoi(r[0]); } catch (...) {}
                    if (n > last_nr) last_nr = n;
                }
            }
        }
    }
    if (fresh) {
        std::ofstream f(csvp, std::ios::binary | std::ios::trunc);
        f << "\xef\xbb\xbf";
        for (size_t k = 0; k < HEADER.size(); ++k) { if (k) f << ';'; f << csv(HEADER[k]); }
        f << "\r\n";
    }
    std::ofstream app(csvp, std::ios::binary | std::ios::app);

    int graded = 0, failed = 0, dup = 0;
    const int total = (int)files.size();
    std::cout << "MOKYTOJAS: rasta ataskaitu: " << total;
    if (skipped_other) std::cout << " (praleista kitokiu failu: " << skipped_other << ")";
    if (skipped_large) std::cout << " (praleista per dideliu: " << skipped_large << ")";
    std::cout << "\n";
    int k = 0;
    for (const Source& s : files) {
        if (cancel && cancel->load()) {
            std::cout << "Sustabdyta po " << k << " is " << total << "\n";
            break;
        }
        ++k;
        if (tick && !tick(k, total)) break;
        std::string hash;
        if (!hash_file(s.path, hash)) {
            std::cout << "[" << k << "/" << total << "] nepavyko perskaityti\n";
            ++failed;
            continue;  // neturim hash — saugiau neirašyti, kad nekartotume kiekvieną kartą
        }
        if (known.count(hash)) { ++dup; std::cout << "[" << k << "/" << total << "] jau ivertintas\n"; continue; }
        std::vector<std::string> row(HEADER.size());
        row[0] = std::to_string(++last_nr);
        row[1] = now_local();
        row[10] = s.display;
        row[11] = hash;
        try {
            ld::Json rep = ld::read_report(s.path);
            ld::Json v = ld::grade(rep);
            row[2] = v["student"]["name"].get<std::string>();
            row[3] = v["student"]["group"].get<std::string>();
            row[4] = v["lab_id"].get<std::string>();
            row[5] = std::to_string(v["variant"].get<int>());
            row[6] = v["grade_10"].is_null() ? std::string("NEVERTINTA") : v["grade_10"].dump();
            if (v["mode"] != "assessment" || v.value("practice_used", false)) row[6] = "MOKYMASIS";
            row[7] = v["points"].dump();
            row[8] = v["max_points"].dump();
            std::string mistakes;
            for (const auto& it : v["items"]) {
                if (it.value("status", std::string()) == "correct") continue;
                if (!mistakes.empty()) mistakes += ", ";
                mistakes += it.value("label", std::string());
            }
            if (mistakes.size() > 180) mistakes = mistakes.substr(0, 177) + "...";
            row[9] = mistakes;
            write_feedback(last_nr, s.display, v);
            ++graded;
            std::cout << "[" << k << "/" << total << "] ivertinta: " << row[4] << " variantas "
                      << row[5] << ", balas " << row[6] << "\n";
        } catch (const std::exception& e) {
            row[2] = row[3] = row[4] = row[5] = row[7] = row[8] = "";
            row[6] = "NEVERTINTA";
            row[9] = message(e.what());
            ++failed;
            std::cout << "[" << k << "/" << total << "] netinkamas failas\n";
        }
        for (size_t c = 0; c < row.size(); ++c) { if (c) app << ';'; app << csv(row[c]); }
        app << "\r\n";
        known.insert(hash);
    }
    app.flush();
    rebuild_zurnalas(csvp);
    std::cout << "Rezultatas: nauji irasai " << (graded + failed) << " (ivertinta " << graded
              << ", neivertinta " << failed << "), jau buvo ivertinti " << dup << "\n";
    std::error_code ec;
    std::cout << "CSV: " << fs::absolute(csvp, ec).string() << "\n";
    std::cout << "Zurnalas: " << fs::absolute("ZURNALAS.csv", ec).string() << "\n";
    return 0;
}

int mokytojas_run(const std::vector<std::string>& args, const std::function<bool(int, int)>& tick,
                  const std::atomic<bool>* cancel) {
    if (args.size() > 1) return 2;
    std::string arg = args.empty() ? std::string(".") : args[0];
    int skipped_other = 0, skipped_large = 0;
    std::vector<Source> files;
    std::error_code isdir_ec;
    const bool is_dir = fs::is_directory(fs::path(arg), isdir_ec);
    std::string folder = is_dir ? std::string() : drive_folder_id(arg);
    if (!folder.empty()) {
        std::string key = drive_key();
        if (key.empty()) {
            std::cerr << "Google Drive API raktas nerastas. Nurodykite ji env "
                         "GRANDINIU_DRIVE_API_KEY arba failo drive_raktas.txt pirma eilute.\n";
            return 1;
        }
        fs::path tmp = fs::temp_directory_path() / ("mokytojas-" + std::to_string(pid_value()));
        std::error_code ec;
        fs::create_directories(tmp, ec);
        if (ec) {
            std::cerr << "Nepavyko sukurti laikino Google Drive katalogo: " << ec.message() << "\n";
            return 1;
        }
        try {
            auto list = drive_list(folder, key, tmp, skipped_other, skipped_large);
            int idx = 0;
            for (const DriveEntry& e : list) {
                fs::path p = drive_download(e, key, tmp, ++idx);
                files.push_back({p, e.name});
            }
            std::cout << "MOKYTOJAS: is Google Drive parsisiusta failu: " << files.size() << "\n";
            const int rc = process(files, skipped_other, skipped_large, tick, cancel);
            std::error_code rm;
            fs::remove_all(tmp, rm);
            return rc;
        } catch (...) {
            std::error_code rm;
            fs::remove_all(tmp, rm);
            throw;
        }
    }
    fs::path root = fs::path(arg);
    if (!is_dir) {
        std::cerr << "Argumentas nera nei Google Drive nuoroda/ID, nei egzistuojantis aplankas: "
                  << arg << "\n";
        return 1;
    }
    for (const fs::path& p : scan_local(root, skipped_other, skipped_large))
        files.push_back({p, fs::relative(p, root).generic_string()});
    return process(files, skipped_other, skipped_large, tick, cancel);
}

int mokytojas(const std::vector<std::string>& args) { return mokytojas_run(args, {}, nullptr); }

// ------------------------------------------------------------------- UI ----
// Naujosios kartos sąsaja: vietinis 127.0.0.1 serveris + naršyklės langas.
// Jokių išorinių bibliotekų — tik C++17 ir platformos socket sluoksnis.
#ifdef _WIN32
#define CLOSESOCK ::closesocket
#else
#define CLOSESOCK ::close
#endif

static const char ui_page_html[] = R"HTML(<!doctype html>
<html lang="lt"><head><meta charset="utf-8">
<title>MOKYTOJAS — automatinis vertinimas</title>
<style>
body{font-family:system-ui,'DejaVu Sans',sans-serif;max-width:980px;margin:24px auto;padding:0 16px;color:#132430;background:#f5f8f9}
h1{font-size:22px;color:#0a6360}
input[type=text]{width:70%;padding:10px;font-size:15px;border:1px solid #9db4ba;border-radius:6px}
button{padding:10px 18px;font-size:15px;border:0;border-radius:6px;background:#0a6360;color:#fff;font-weight:600;cursor:pointer}
button.antras{background:#8aa4ab}
button:disabled{background:#b9c8cc;cursor:default}
#status{margin:14px 0;padding:10px 14px;border-radius:6px;background:#e7efef;min-height:22px}
#status.klaida{background:#f6e0e0}
table{border-collapse:collapse;margin-top:14px;background:#fff}
th,td{border:1px solid #c3d2d6;padding:6px 10px;font-size:14px;text-align:center}
th{background:#0a6360;color:#fff}
td:first-child,td:nth-child(2){text-align:left}
.kelias{font-size:13px;color:#4d6570;margin-top:18px;line-height:1.6}
</style></head><body>
<h1>MOKYTOJAS — automatinis laboratorinių vertinimas</h1>
<p><input id="arg" type="text" placeholder="Google Drive aplanko nuoroda arba vietinis aplankas (tuščia = dabartinis)">
<button id="go">Įvertinti</button> <button id="stop" class="antras" disabled>Sustabdyti</button>
<button id="quit" class="antras">Baigti programą</button></p>
<div id="status">Paruošta.</div>
<table id="zurnalas"></table>
<div class="kelias" id="failai"></div>
<script>
const $=id=>document.getElementById(id);
async function statusas(){
  try{
    const r=await fetch('/status');const s=await r.json();
    const st=$('status');
    st.className=s.state==='error'?'klaida':'';
    st.textContent=s.message+(s.total?(' · '+s.done+' / '+s.total+' ataskaitų'):'')+(s.state==='running'?' …':'');
    $('go').disabled=s.running;$('stop').disabled=!s.running;
    if(s.state==='done'&&s.total>0)zurnalas();
  }catch(e){}
}
async function zurnalas(){
  const r=await fetch('/zurnalas');const txt=await r.text();
  const lines=txt.replace(/^﻿/,'').split(/\r?\n/).filter(x=>x.trim());
  if(!lines.length)return;
  const parse=l=>{const f=l.split('";"').map(x=>x.replace(/^"|"$/g,''));return f.length===1?l.split(';'):f};
  const rows=lines.map(parse);
  const table=$('zurnalas');table.replaceChildren();
  const head=document.createElement('tr');
  rows[0].forEach(value=>{const cell=document.createElement('th');cell.textContent=value;head.appendChild(cell);});
  table.appendChild(head);
  rows.slice(1).forEach(row=>{const tr=document.createElement('tr');
    row.forEach(value=>{const cell=document.createElement('td');cell.textContent=value||'—';tr.appendChild(cell);});
    table.appendChild(tr);
  });
}
$('go').onclick=async()=>{
  const arg=encodeURIComponent($('arg').value.trim()||'.');
  await fetch('/start?arg='+arg);statusas();
};
$('stop').onclick=async()=>{await fetch('/stop');statusas();};
$('quit').onclick=async()=>{
  $('quit').disabled=true;
  try{await fetch('/quit');}catch(e){}
  $('go').disabled=true;$('stop').disabled=true;
  $('status').textContent='Programa uždaryta. Šį naršyklės langą galite užverti.';
};
$('failai').textContent='Rezultatai rašomi dabartiniame darbo kataloge: IVERTINIMAI.csv (istorijos žurnalas), ZURNALAS.csv (studentų × darbų lentelė) ir atsiliepimai/ (detalūs paaiškinimai). Programą užbaikite mygtuku „Baigti programą“ arba Ctrl+C terminale.';
statusas();setInterval(statusas,700);
</script></body></html>)HTML";

struct UiState {
    std::atomic<bool> running{false}, cancel{false}, quit{false};
    std::atomic<int> done{0}, total{0};
    std::mutex mtx;
    std::string state = "idle", message = "Paruošta.";
    void set(const std::string& s, const std::string& m) {
        std::lock_guard<std::mutex> l(mtx);
        state = s;
        message = m;
    }
    std::pair<std::string, std::string> get() {
        std::lock_guard<std::mutex> l(mtx);
        return {state, message};
    }
};

std::string json_escape(const std::string& s) {
    std::string r;
    for (unsigned char c : s) {
        if (c == '"' || c == '\\') { r += '\\'; r += (char)c; }
        else if (c < 0x20) { char b[8]; std::snprintf(b, sizeof b, "\\u%04x", c); r += b; }
        else r += (char)c;
    }
    return r;
}

std::string urldecode(const std::string& s) {
    std::string r;
    for (std::size_t i = 0; i < s.size(); ++i) {
        if (s[i] == '%' && i + 2 < s.size()) {
            auto hex = [](char c) -> int {
                if (c >= '0' && c <= '9') return c - '0';
                if (c >= 'a' && c <= 'f') return c - 'a' + 10;
                if (c >= 'A' && c <= 'F') return c - 'A' + 10;
                return -1;
            };
            int hi = hex(s[i + 1]), lo = hex(s[i + 2]);
            if (hi >= 0 && lo >= 0) { r += (char)(hi * 16 + lo); i += 2; continue; }
        }
        if (s[i] == '+') r += ' ';
        else r += s[i];
    }
    return r;
}

void http_send(long long c, const std::string& type, const std::string& body, int code = 200) {
    const char* why = code == 200 ? "OK" : code == 404 ? "Not Found" : code == 409 ? "Conflict" : "Error";
    std::string head = "HTTP/1.1 " + std::to_string(code) + " " + why +
                       "\r\nContent-Type: " + type + "; charset=utf-8\r\nContent-Length: " +
                       std::to_string(body.size()) + "\r\nConnection: close\r\n\r\n";
    ::send((int)c, head.data(), (int)head.size(), 0);
    ::send((int)c, body.data(), (int)body.size(), 0);
}

void open_browser(const std::string& url) {
    if (std::getenv("MOKYTOJAS_NO_BROWSER")) return;
    fs::path err = fs::temp_directory_path() / "mokytojas-atidarymas.err";
#ifdef _WIN32
    run_prog({"cmd", "/c", "start", "", url}, err);
#else
    if (!std::getenv("DISPLAY")) return;
    run_prog({"xdg-open", url}, err);
#endif
}

int ui_run() {
#ifdef _WIN32
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        std::cerr << "Nepavyko inicijuoti tinklo (WSAStartup).\n";
        return 1;
    }
#endif
    int s = (int)::socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) { std::cerr << "Nepavyko atidaryti socketo.\n"; return 1; }
    int one = 1;
    ::setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char*)&one, sizeof one);
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(0x7F000001);  // tik vietinis
    addr.sin_port = 0;                          // laisvas portas
    if (::bind(s, (sockaddr*)&addr, sizeof addr) != 0 || ::listen(s, 8) != 0) {
        std::cerr << "Nepavyko prisijungti vietinio serverio.\n";
        CLOSESOCK(s);
        return 1;
    }
    sockaddr_in bound{};
    socklen_t blen = sizeof bound;
    ::getsockname(s, (sockaddr*)&bound, &blen);
    const int port = ntohs(bound.sin_port);
    std::cout << "MOKYTOJAS UI: http://127.0.0.1:" << port << std::endl;  // flush — vamzdis blokinis
    std::cout << "Darbo katalogas: " << fs::current_path().string() << std::endl;
    open_browser("http://127.0.0.1:" + std::to_string(port));

    UiState st;
    std::thread worker;
    while (!st.quit.load()) {
        long long c = (long long)::accept(s, nullptr, nullptr);
        if (c < 0) continue;
#ifdef _WIN32
        DWORD ms = 5000;
        ::setsockopt((int)c, SOL_SOCKET, SO_RCVTIMEO, (const char*)&ms, sizeof ms);
#else
        timeval tv{5, 0};
        ::setsockopt((int)c, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof tv);
#endif
        std::string req;
        char buf[2048];
        while (req.find("\r\n\r\n") == std::string::npos && req.size() < 16384) {
            int n = (int)::recv((int)c, buf, sizeof buf, 0);
            if (n <= 0) break;
            req.append(buf, (size_t)n);
        }
        std::size_t sp = req.find(' ');
        std::string path = (sp == std::string::npos) ? "/" : req.substr(sp + 1, req.find(' ', sp + 1) - sp - 1);
        std::size_t qm = path.find('?');
        std::string route = path.substr(0, qm);
        std::string query = (qm == std::string::npos) ? "" : path.substr(qm + 1);
        std::size_t eq = query.find("arg=");
        std::string arg = (eq == std::string::npos) ? "" : urldecode(query.substr(eq + 4));

        if (route == "/" || route == "/index.html") {
            http_send(c, "text/html", std::string(ui_page_html, sizeof ui_page_html - 1));
        } else if (route == "/status") {
            auto sm = st.get();
            std::string j = "{\"state\":\"" + json_escape(sm.first) + "\",\"message\":\"" + json_escape(sm.second) +
                "\",\"running\":" + (st.running.load() ? "true" : "false") +
                ",\"done\":" + std::to_string(st.done.load()) +
                ",\"total\":" + std::to_string(st.total.load()) + "}";
            http_send(c, "application/json", j);
        } else if (route == "/start") {
            if (st.running.load()) { http_send(c, "application/json", "{\"ok\":false,\"error\":\"jau veikia\"}", 409); }
            else if (arg.empty()) { http_send(c, "application/json", "{\"ok\":false,\"error\":\"nenurodytas kelias\"}", 400); }
            else {
                if (worker.joinable()) worker.join();
                st.cancel = false; st.done = 0; st.total = 0;
                st.set("running", "Pradedama…");
                st.running = true;  // sinchroniškai — pirmoji /status užklausa turi matyti
                worker = std::thread([&, arg]() {
                    try {
                        int rc = mokytojas_run({arg}, [&](int k, int n) {
                            st.done = k; st.total = n;
                            return !st.cancel.load();
                        }, &st.cancel);
                        st.set(rc == 0 ? "done" : "error",
                               rc == 0 ? "Įvertinimas baigtas. Žurnalas ir atsiliepimai paruošti."
                                       : "Nepavyko baigti (kodas " + std::to_string(rc) + ").");
                    } catch (const std::exception& e) {
                        st.set("error", e.what());
                    }
                    st.running = false;
                });
                http_send(c, "application/json", "{\"ok\":true}");
            }
        } else if (route == "/stop") {
            st.cancel = true;
            st.set("running", "Stabdoma…");
            http_send(c, "application/json", "{\"ok\":true}");
        } else if (route == "/zurnalas") {
            if (st.running.load()) { http_send(c, "text/csv", "vertinama...", 503); }
            else {
                std::error_code ec;
                std::string body = read_file(fs::absolute("ZURNALAS.csv", ec));
                if (body.empty()) body = "\xef\xbb\xbfVardas;Grup\xc4\x97\n";
                http_send(c, "text/csv", body);
            }
        } else if (route == "/quit") {
            st.cancel = true;
            http_send(c, "application/json", "{\"ok\":true}");
            CLOSESOCK((int)c);
            break;
        } else {
            http_send(c, "text/plain", "nerasta", 404);
        }
        CLOSESOCK((int)c);
    }
    // The worker captures st by reference. It must stop before st is destroyed;
    // detached execution here could access freed memory when the window closes.
    st.cancel = true;
    if (worker.joinable()) worker.join();
    CLOSESOCK(s);
#ifdef _WIN32
    WSACleanup();
#endif
    return 0;
}

}  // namespace

#ifdef _WIN32
int wmain(int argc, wchar_t** argv) {
    if (argc > 2) { std::cerr << "mokytojas [aplankas | Drive nuoroda arba ID]\n"; return 2; }
    std::vector<std::string> args;
    for (int k = 1; k < argc; ++k) {
        std::wstring w = argv[k];
        if (w == L"--ui") return ui_run();
        int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0, nullptr, nullptr);
        std::string s((size_t)n, '\0');
        WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &s[0], n, nullptr, nullptr);
        args.push_back(s);
    }
    try { return mokytojas(args); }
    catch (const std::exception& e) { std::cerr << e.what() << "\n"; return 1; }
}
#else
int main(int argc, char** argv) {
    if (argc > 2) { std::cerr << "mokytojas [aplankas | Drive nuoroda arba ID]\n"; return 2; }
    std::vector<std::string> args;
    for (int k = 1; k < argc; ++k) {
        if (std::string(argv[k]) == "--ui") return ui_run();
        args.push_back(argv[k]);
    }
    try { return mokytojas(args); }
    catch (const std::exception& e) { std::cerr << e.what() << "\n"; return 1; }
}
#endif
