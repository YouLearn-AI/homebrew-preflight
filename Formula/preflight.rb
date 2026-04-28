class Preflight < Formula
  desc "End-to-end QA testing for shipped Electron desktop apps"
  homepage "https://github.com/YouLearn-AI/preflight"
  version "0.2.1"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/YouLearn-AI/preflight/releases/download/v0.2.1/preflight-0.2.1-darwin-arm64.tar.gz"
      sha256 ""
    end
  end

  depends_on :macos
  depends_on arch: :arm64
  depends_on "ffmpeg"
  depends_on cask: "blackhole-2ch"
  depends_on "tesseract" => :optional

  def install
    bin.install "bin/preflight"
    bin.install "bin/preflight-brain" if File.exist?("bin/preflight-brain")
    (pkgshare/"journeys").install Dir["share/preflight/journeys/*"] if Dir.exist?("share/preflight/journeys")
    (pkgshare/"fixtures").install Dir["share/preflight/fixtures/*"] if Dir.exist?("share/preflight/fixtures")
    pkgshare.install "share/preflight/MEMORY.md" if File.exist?("share/preflight/MEMORY.md")
    pkgshare.install "share/preflight/LICENSE" if File.exist?("share/preflight/LICENSE")
  end

  def caveats
    <<~CAV
      Two more deps need installing — they have no Homebrew tap:

        preflight doctor --install-missing

      handles audiokit (clones github.com/YouLearn-AI/audiokit + npm link)
      and cua-driver (upstream installer from github.com/trycua/cua), and
      opens System Settings panes for the Privacy permissions:
      Accessibility, Input Monitoring, Screen Recording, Microphone.

      After granting, fully QUIT and RELAUNCH your terminal.

      Required env:
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
