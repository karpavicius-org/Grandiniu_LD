# Grandiniu LD license and signed release

The English and Lithuanian proprietary license identifies Rimas Karpavičius as the declared rights holder of original protectable contributions. The five-page Word/PDF document records the historical Git evidence and the archive SSH signature. Historical commit signatures are unchanged.

The final distribution archive includes the student application, all LD1–LD12 methodological documents, licenses, and checksums. It is stored in the user-designated Drive folder:

https://drive.google.com/drive/folders/1kw6QCnR_Z3sq3v1aQfZVnMzqBqC4lE4K

Signed archive: https://drive.google.com/file/d/1JUh3fAFIqAB7ql2i4I3zyUHRWtyoBH6G/view?usp=drivesdk

Archive SHA-256: `fca4e2a128d8a6a9d0b0a43bd112601d9e472a0a1e76d65e9ddc2ce24a829ffa`

Project release key fingerprint: `SHA256:M7TjtCmzarwlyBhi420fRarK0Bpth1qskfXS175U6X0`

The `ssh/` directory contains the public key, detached signature, verification scripts and executed-test receipt. Pin the fingerprint through a trusted source before using the supplied allowed_signers file. This is a newly generated project key, not an independently authenticated personal key of the named rights holder.

The encrypted private-key backup is saved separately in Drive; its passphrase is delivered privately and is excluded from Drive and this repository. The original unencrypted private key is excluded from all published files. Backup restoration and signing were tested, and an incorrect passphrase was rejected.

The document builder is preserved in `source/`. To reproduce its full input layout, extract `surinkimo_saltiniai/` from the distribution archive and use its source files with python-docx. The signed archive is kept immutable; it is not regenerated merely to add this publication commit identifier.
