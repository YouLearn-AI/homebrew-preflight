require "download_strategy"

# Custom strategy: download release assets from a private GitHub repo using
# the user's HOMEBREW_GITHUB_API_TOKEN. Hits api.github.com with the asset
# id, requesting Accept: application/octet-stream — GitHub redirects to a
# pre-signed CDN URL we can fetch with curl.
#
# Set the token before installing:
#   export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)
#   brew install youlearn-ai/preflight/preflight
class GitHubPrivateAssetStrategy < CurlDownloadStrategy
  def _fetch(url:, resolved_url:, timeout:)
    token = ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", nil)
    raise CurlDownloadStrategyError.new(url, "HOMEBREW_GITHUB_API_TOKEN is not set. Run: export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)") if token.nil? || token.empty?

    curl_download(
      "--header", "Accept: application/octet-stream",
      "--header", "Authorization: Bearer #{token}",
      "--location",
      url,
      to: temporary_path,
      timeout: timeout,
    )
  end
end

class Preflight < Formula
  desc "End-to-end QA testing for shipped Electron desktop apps"
  homepage "https://github.com/YouLearn-AI/preflight"
  version "0.2.4"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://api.github.com/repos/YouLearn-AI/preflight/releases/assets/407632265",
          using: GitHubPrivateAssetStrategy
      sha256 "7826af34b562687d65c636bfcd83a62fba084a8931a32411410897f59b63c1f7"
    end
  end

  depends_on :macos
  depends_on arch: :arm64
  depends_on "ffmpeg"
  depends_on "tesseract" => :optional

  def install
    (libexec/"preflight").install Dir["libexec/preflight/*"] if Dir.exist?("libexec/preflight")
    bin.install "bin/preflight"
    bin.install "bin/preflight-brain" if File.exist?("bin/preflight-brain")
    (pkgshare/"journeys").install Dir["share/preflight/journeys/*"] if Dir.exist?("share/preflight/journeys")
    (pkgshare/"fixtures").install Dir["share/preflight/fixtures/*"] if Dir.exist?("share/preflight/fixtures")
    pkgshare.install "share/preflight/MEMORY.md" if File.exist?("share/preflight/MEMORY.md")
    pkgshare.install "share/preflight/LICENSE" if File.exist?("share/preflight/LICENSE")
  end

  def caveats
    <<~CAV
      Three more deps need installing (no Homebrew tap, or cask):

        brew install --cask blackhole-2ch
        preflight doctor --install-missing

      Doctor handles audiokit (clones github.com/YouLearn-AI/audiokit + npm link)
      and cua-driver (upstream installer from github.com/trycua/cua), and
      opens System Settings panes for Privacy permissions:
      Accessibility, Input Monitoring, Screen Recording, Microphone.

      After granting, fully QUIT and RELAUNCH your terminal.

      Required env (formula uses HOMEBREW_GITHUB_API_TOKEN to fetch from
      the private release; export it before brew install/upgrade):
        export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)
        OPENAI_API_KEY  https://platform.openai.com/api-keys
        GEMINI_API_KEY  https://aistudio.google.com/apikey (recommended)

      First runs:
        preflight doctor
        preflight workflow smoke
        preflight workflow jonah-customer-video --auto-loop 2
    CAV
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/preflight --version")
  end
end
