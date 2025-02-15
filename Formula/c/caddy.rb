class Caddy < Formula
  desc "Powerful, enterprise-ready, open source web server with automatic HTTPS"
  homepage "https://caddyserver.com/"
  url "https://github.com/caddyserver/caddy/archive/refs/tags/v2.7.6.tar.gz"
  sha256 "e1c524fc4f4bd2b0d39df51679d9d065bb811e381b7e4e51466ba39a0083e3ed"
  license "Apache-2.0"
  head "https://github.com/caddyserver/caddy.git", branch: "master"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "44451e4f00410a97da192ab349ab94481c7f9ae86113515535f0a792b45092d0"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "44451e4f00410a97da192ab349ab94481c7f9ae86113515535f0a792b45092d0"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "44451e4f00410a97da192ab349ab94481c7f9ae86113515535f0a792b45092d0"
    sha256 cellar: :any_skip_relocation, sonoma:         "3b8ed9ad1a954ecd9b0725640513c531df9587071594414276159da6462a12d5"
    sha256 cellar: :any_skip_relocation, ventura:        "3b8ed9ad1a954ecd9b0725640513c531df9587071594414276159da6462a12d5"
    sha256 cellar: :any_skip_relocation, monterey:       "3b8ed9ad1a954ecd9b0725640513c531df9587071594414276159da6462a12d5"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "d338d76fc8ebefae48a22e703035082db304871c8d78c97eab6513d83fb6621f"
  end

  depends_on "go" => :build

  resource "xcaddy" do
    url "https://github.com/caddyserver/xcaddy/archive/refs/tags/v0.3.5.tar.gz"
    sha256 "41188931a3346787f9f4bc9b0f57db1ba59ab228113dcf0c91382e40960ee783"
  end

  def install
    revision = build.head? ? version.commit : "v#{version}"

    resource("xcaddy").stage do
      system "go", "run", "cmd/xcaddy/main.go", "build", revision, "--output", bin/"caddy"
    end

    generate_completions_from_executable("go", "run", "cmd/caddy/main.go", "completion")

    system bin/"caddy", "manpage", "--directory", buildpath/"man"

    man8.install Dir[buildpath/"man/*.8"]
  end

  service do
    run [opt_bin/"caddy", "run", "--config", etc/"Caddyfile"]
    keep_alive true
    error_log_path var/"log/caddy.log"
    log_path var/"log/caddy.log"
  end

  test do
    port1 = free_port
    port2 = free_port

    (testpath/"Caddyfile").write <<~EOS
      {
        admin 127.0.0.1:#{port1}
      }

      http://127.0.0.1:#{port2} {
        respond "Hello, Caddy!"
      }
    EOS

    fork do
      exec bin/"caddy", "run", "--config", testpath/"Caddyfile"
    end
    sleep 2

    assert_match "\":#{port2}\"",
      shell_output("curl -s http://127.0.0.1:#{port1}/config/apps/http/servers/srv0/listen/0")
    assert_match "Hello, Caddy!", shell_output("curl -s http://127.0.0.1:#{port2}")

    assert_match version.to_s, shell_output("#{bin}/caddy version")
  end
end
