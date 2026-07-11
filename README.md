<h1>⚙️ DevOps-Toolkit</h1>

<p>
  A <strong>one-shot DevOps environment bootstrapper</strong> built in Bash that
  installs and configures the entire toolchain a DevOps/Cloud engineer needs —
  <strong>Docker, Kubernetes tooling, IaC, and cloud CLIs</strong> — in a single command.
</p>

<p>
  Idempotent, colorized, and animated — re-run it as many times as you like,
  it only installs what's missing.
</p>

<hr>

<h2>✨ Features</h2>
<ul>
  <li>🐳 <strong>Docker Engine</strong> installation + user group setup</li>
  <li>☸️ <strong>Kubernetes tooling</strong>
    <ul>
      <li>Kind (Kubernetes in Docker)</li>
      <li>kubectl (latest stable)</li>
      <li>Helm</li>
      <li>k9s (terminal UI for Kubernetes)</li>
      <li>kubectx & kubens</li>
    </ul>
  </li>
  <li>🏗️ <strong>Infrastructure as Code</strong> — Terraform (via HashiCorp apt repo)</li>
  <li>☁️ <strong>AWS CLI v2</strong></li>
  <li>🧰 <strong>Everyday utilities</strong> — git, jq, yq, tmux, htop, unzip</li>
  <li>🔁 <strong>Idempotent</strong> — safe to re-run, skips already-installed tools</li>
  <li>🎨 <strong>Colorized terminal output</strong></li>
  <li>⏳ <strong>Spinner + progress bar animations</strong> for every step</li>
  <li>📊 <strong>Version summary table</strong> printed at the end</li>
  <li>❌ <strong>Error handling</strong> — fails loudly with logs, not silently</li>
</ul>
<hr>

<h2>📸 Sample Output</h2>
<p>
  <img src="https://github.com/user-attachments/assets/ccd7ec84-be42-48dc-92a4-6ca7fc3fee52" width="606" height="813" alt="Sample terminal output of DevOps-Toolkit installer">
</p>
<hr>

<h2>🛠️ What Gets Installed</h2>
<table>
  <tr><th>Tool</th><th>Purpose</th></tr>
  <tr><td>Docker</td><td>Container runtime</td></tr>
  <tr><td>Kind</td><td>Local Kubernetes clusters in Docker</td></tr>
  <tr><td>kubectl</td><td>Kubernetes CLI</td></tr>
  <tr><td>Helm</td><td>Kubernetes package manager</td></tr>
  <tr><td>Terraform</td><td>Infrastructure as Code</td></tr>
  <tr><td>AWS CLI v2</td><td>AWS cloud management</td></tr>
  <tr><td>k9s</td><td>Terminal UI for Kubernetes clusters</td></tr>
  <tr><td>kubectx / kubens</td><td>Fast context & namespace switching</td></tr>
  <tr><td>jq / yq</td><td>JSON / YAML processing</td></tr>
  <tr><td>git, tmux, htop</td><td>Everyday CLI essentials</td></tr>
</table>
<hr>

<h2>🚀 Installation & Usage</h2>

<h3>1. Clone the repository</h3>
<pre><code>git clone https://github.com/niranjanmishra004/DevOps-Toolkit.git</code></pre>

<h3>2. Navigate into the directory</h3>
<pre><code>cd DevOps-Toolkit</code></pre>

<h3>3. Make it executable</h3>
<pre><code>chmod +x toolkit.sh</code></pre>
<h3>4. Run the script</h3>
<pre><code>./toolkit.sh</code></pre>

<p><strong>⚠️ Note:</strong> Some commands require <code>sudo</code> privileges. If Docker was just installed, log out/in (or run <code>newgrp docker</code>) to use it without <code>sudo</code>.</p>
<hr>

<h2>⚙️ How It Works</h2>
<ul>
  <li>Detects CPU architecture (<code>x86_64</code> / <code>arm64</code>) via <code>uname -m</code></li>
  <li>Checks each tool with <code>command -v</code> before installing — skips anything already present</li>
  <li>Installs everything through official sources:
    <ul>
      <li><code>apt</code> for Docker & base utilities</li>
      <li>Official binaries for Kind, kubectl, k9s, yq</li>
      <li>Official install script for Helm</li>
      <li>HashiCorp apt repo for Terraform</li>
      <li>Official installer for AWS CLI v2</li>
      <li>GitHub clone for kubectx/kubens</li>
    </ul>
  </li>
  <li>Shows a spinner + progress bar for every step</li>
  <li>Prints a final table with the installed version of each tool</li>
</ul>
<hr>

<h2>📂 Project Structure</h2>
<pre><code>
DevOps-Toolkit/
│── devops-setup.sh
└── README.md
    
</code></pre>
<hr>

<h2>🎯 Use Cases</h2>
<ul>
  <li>🖥️ Bootstrapping a fresh VM or dev laptop for DevOps work</li>
  <li>☸️ Spinning up local Kubernetes learning/test environments (Kind + kubectl + k9s)</li>
  <li>🏗️ Setting up an IaC-ready machine (Terraform + AWS CLI)</li>
  <li>👥 Standardizing tooling across a team so everyone runs the same versions</li>
  <li>🐳 CI runner / container image provisioning</li>
</ul>
<hr>

<h2>🧠 Why This Project?</h2>
<p>
  Setting up a DevOps workstation usually means hunting down a dozen install
  commands from a dozen different docs. This script collapses all of that into
  one idempotent, animated, one-command setup — so you (or your whole team)
  can go from a blank machine to a fully equipped DevOps environment in minutes.
</p>
<hr>

<h2>🤝 Contributing</h2>
<p>Contributions are welcome! Feel free to fork this repo, add support for more tools/distros, and submit a pull request.</p>
<hr>

<h2>⭐ Support</h2>
<p>If you found this useful, consider giving it a ⭐ on GitHub!</p>
