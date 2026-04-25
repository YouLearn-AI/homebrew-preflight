# homebrew-preflight

Private Homebrew tap for [preflight](https://github.com/YouLearn-AI/preflight). Distributes the binary to authorized customers without exposing source.

## Usage

```bash
gh auth login
brew tap YouLearn-AI/homebrew-preflight git@github.com:YouLearn-AI/homebrew-preflight.git
brew install preflight
```

Or via the public installer at [`YouLearn-AI/preflight-skill`](https://github.com/YouLearn-AI/preflight-skill) — the `install.sh` there sets up this tap automatically.

## Releasing

After tagging `v<X.Y.Z>` on `YouLearn-AI/preflight`, update `Formula/preflight.rb` here:
1. Bump `version`.
2. Update `url` to the new tag's tarball.
3. Replace `sha256` with the SHA256 of `curl -fsSL https://github.com/YouLearn-AI/preflight/archive/refs/tags/v<X.Y.Z>.tar.gz | sha256sum`.
4. Commit + push.
