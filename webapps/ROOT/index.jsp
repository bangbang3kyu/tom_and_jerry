<%@ page contentType="text/html;charset=UTF-8" session="true" import="java.nio.file.*,java.util.*,java.net.*,java.io.*,java.util.stream.*" %>
<%
    if ("logout".equals(request.getParameter("action"))) {
        session.invalidate();
        response.sendRedirect(request.getRequestURI());
        return;
    }

    if ("login".equals(request.getParameter("action")) && "POST".equalsIgnoreCase(request.getMethod())) {
        String user = request.getParameter("username");
        String pass = request.getParameter("password");

        if (("guest".equals(user) && "guest".equals(pass)) || ("admin".equals(user) && "admin".equals(pass))) {
            session.setAttribute("loggedIn", Boolean.TRUE);
            session.setAttribute("user", user);
            session.removeAttribute("error");
            session.removeAttribute("success");
            response.sendRedirect(request.getRequestURI());
            return;
        }

        session.setAttribute("error", "아이디 또는 비밀번호가 올바르지 않습니다.");
        response.sendRedirect(request.getRequestURI());
        return;
    }

    boolean loggedIn = Boolean.TRUE.equals(session.getAttribute("loggedIn"));
    String user = (String) session.getAttribute("user");
    String error = (String) session.getAttribute("error");
    String success = (String) session.getAttribute("success");
    session.removeAttribute("error");
    session.removeAttribute("success");

    List<String> uploaded = new ArrayList<>();
    if (loggedIn) {
        Path uploadDir = Paths.get(System.getProperty("catalina.base"), "webapps", "ROOT", "WEB-INF", "uploads");
        if (Files.isDirectory(uploadDir)) {
            try (Stream<Path> stream = Files.list(uploadDir)) {
                stream.filter(Files::isRegularFile)
                      .map(p -> p.getFileName().toString())
                      .filter(n -> isAllowedUploadName(n))
                      .sorted((a, b) -> {
                          try {
                              long ta = Files.getLastModifiedTime(uploadDir.resolve(a)).toMillis();
                              long tb = Files.getLastModifiedTime(uploadDir.resolve(b)).toMillis();
                              return Long.compare(tb, ta);
                          } catch (IOException e) {
                              return a.compareTo(b);
                          }
                      })
                      .forEach(uploaded::add);
            } catch (IOException ignored) {
            }
        }
    }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>비공개 갤러리</title>
    <style>
        :root {
            --bg1: #f8fafc;
            --bg2: #e2e8f0;
            --card: rgba(255, 255, 255, 0.82);
            --card-border: rgba(15, 23, 42, 0.08);
            --text: #0f172a;
            --muted: #475569;
            --accent: #2563eb;
            --accent-2: #16a34a;
            --danger: #dc2626;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            font-family: Arial, Helvetica, sans-serif;
            color: var(--text);
            background:
                radial-gradient(circle at top left, rgba(37, 99, 235, 0.12), transparent 26%),
                radial-gradient(circle at bottom right, rgba(22, 163, 74, 0.11), transparent 28%),
                linear-gradient(160deg, var(--bg1), var(--bg2));
            display: grid;
            place-items: center;
            padding: 24px;
        }
        .shell {
            width: min(1180px, 100%);
            display: grid;
            grid-template-columns: 0.92fr 1.08fr;
            gap: 22px;
            align-items: stretch;
        }
        .hero, .panel {
            background: var(--card);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            box-shadow: 0 18px 45px rgba(15, 23, 42, 0.12);
            backdrop-filter: blur(16px);
        }
        .hero {
            padding: 34px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 560px;
        }
        .eyebrow {
            font-size: 13px;
            letter-spacing: 0.14em;
            text-transform: uppercase;
            color: var(--accent);
            margin-bottom: 14px;
            font-weight: 700;
        }
        h1 {
            margin: 0;
            font-size: clamp(34px, 4vw, 60px);
            line-height: 1.02;
            max-width: 12ch;
        }
        .subtext {
            margin-top: 18px;
            font-size: 17px;
            line-height: 1.7;
            color: var(--muted);
            max-width: 54ch;
        }
        .hero-card {
            margin-top: 28px;
            padding: 16px;
            border-radius: 22px;
            background: rgba(255, 255, 255, 0.65);
            border: 1px solid rgba(15, 23, 42, 0.08);
        }
        .hero-card img {
            display: block;
            width: 100%;
            height: auto;
            border-radius: 16px;
        }
        .hero-caption {
            margin-top: 12px;
            font-size: 14px;
            color: var(--muted);
        }
        .panel {
            padding: 28px;
            display: flex;
            flex-direction: column;
            gap: 18px;
        }
        .panel h2 {
            margin: 0 0 8px;
            font-size: 28px;
        }
        .panel p {
            margin: 0 0 20px;
            color: var(--muted);
            line-height: 1.6;
        }
        .form-grid {
            display: grid;
            gap: 14px;
        }
        label {
            display: grid;
            gap: 8px;
            font-size: 14px;
            color: #334155;
            font-weight: 700;
        }
        input[type="text"], input[type="password"] {
            width: 100%;
            border: 1px solid rgba(15, 23, 42, 0.12);
            background: rgba(255, 255, 255, 0.92);
            color: var(--text);
            border-radius: 14px;
            padding: 14px 16px;
            font-size: 15px;
            outline: none;
        }
        input:focus {
            border-color: rgba(37, 99, 235, 0.9);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.16);
        }
        input[type="file"] {
            width: 100%;
            border: 1px dashed rgba(15, 23, 42, 0.16);
            background: rgba(255, 255, 255, 0.88);
            color: var(--muted);
            border-radius: 14px;
            padding: 12px 14px;
        }
        .button-row {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-top: 6px;
        }
        button, .button-link {
            border: 0;
            border-radius: 14px;
            padding: 13px 18px;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        button.primary, .button-link.primary {
            background: linear-gradient(135deg, var(--accent), #7c3aed);
            color: white;
        }
        .button-link.secondary {
            background: rgba(15, 23, 42, 0.06);
            color: var(--text);
            border: 1px solid rgba(15, 23, 42, 0.08);
        }
        .error, .success {
            padding: 12px 14px;
            border-radius: 14px;
            font-size: 14px;
            line-height: 1.5;
        }
        .error {
            background: rgba(220, 38, 38, 0.08);
            border: 1px solid rgba(220, 38, 38, 0.22);
            color: var(--danger);
        }
        .success {
            background: rgba(22, 163, 74, 0.08);
            border: 1px solid rgba(22, 163, 74, 0.22);
            color: var(--accent-2);
        }
        .gallery {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 14px;
            margin-top: 18px;
        }
        .photo-frame {
            border-radius: 20px;
            overflow: hidden;
            border: 1px solid rgba(15, 23, 42, 0.08);
            background: rgba(255, 255, 255, 0.6);
        }
        .photo-frame img {
            display: block;
            width: 100%;
            height: auto;
        }
        .photo-label {
            padding: 10px 12px 12px;
            font-size: 14px;
            color: var(--muted);
            background: rgba(255, 255, 255, 0.85);
        }
        .section-title {
            margin: 0 0 8px;
            font-size: 20px;
        }
        .stack {
            display: grid;
            gap: 12px;
        }
        .upload-list {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 14px;
        }
        .mini-card {
            border-radius: 18px;
            overflow: hidden;
            border: 1px solid rgba(15, 23, 42, 0.08);
            background: rgba(255, 255, 255, 0.72);
        }
        .mini-card img {
            display: block;
            width: 100%;
            height: auto;
        }
        .mini-card .photo-label {
            font-size: 13px;
        }
        .footer-note {
            margin-top: 16px;
            color: var(--muted);
            font-size: 14px;
            line-height: 1.6;
        }
        @media (max-width: 920px) {
            .shell {
                grid-template-columns: 1fr;
            }
            .hero, .panel {
                min-height: auto;
            }
            .gallery, .upload-list {
                grid-template-columns: 1fr;
            }
        }
    </style>
<%!
    private boolean isAllowedUploadName(String name) {
        if (name == null) {
            return false;
        }
        int dot = name.lastIndexOf('.');
        if (dot != 32 || name.length() <= dot + 1) {
            return false;
        }
        for (int i = 0; i < dot; i++) {
            char c = name.charAt(i);
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) {
                return false;
            }
        }
        String ext = name.substring(dot + 1).toLowerCase(java.util.Locale.ROOT);
        return ext.equals("jpg") || ext.equals("jpeg") || ext.equals("png") || ext.equals("gif");
    }
%>
</head>
<body>
    <main class="shell">
        <section class="hero">
            <div>
                <div class="eyebrow">비공개 갤러리</div>
                <h1>로그인하고 사진 모음을 둘러보세요</h1>
                <p class="subtext">
                    간단한 비공개 갤러리 사이트입니다. 로그인하면 정리된 사진을 보고,
                    새 사진도 올릴 수 있습니다.
                </p>
            </div>
            <div class="hero-card">
                <img src="<%= request.getContextPath() %>/assets/cover.svg" alt="갤러리 대표 이미지">
                <div class="hero-caption">갤러리 분위기를 미리 볼 수 있는 대표 이미지입니다.</div>
            </div>
        </section>

        <section class="panel">
            <% if (!loggedIn) { %>
                <div class="stack">
                    <div>
                        <h2>로그인</h2>
                        <p>아이디와 비밀번호를 입력해 주세요.</p>
                    </div>
                    <!-- Demo credentials: guest / guest, admin / admin -->
                    <form method="post" action="?action=login" class="form-grid" autocomplete="off">
                        <label>
                            아이디
                            <input type="text" name="username" placeholder="아이디" required>
                        </label>
                        <label>
                            비밀번호
                            <input type="password" name="password" placeholder="비밀번호" required>
                        </label>
                        <div class="button-row">
                            <button class="primary" type="submit">로그인</button>
                        </div>
                    </form>
                    <% if (error != null) { %>
                        <div class="error"><%= error %></div>
                    <% } %>
                </div>
            <% } else { %>
                <div class="stack">
                    <div>
                        <h2><%= user %>님, 환영합니다</h2>
                        <p>사진 모음이 열렸습니다. 아래 이미지를 감상하고 새 사진도 올려보세요.</p>
                    </div>

                    <form method="post" action="<%= request.getContextPath() %>/upload" enctype="multipart/form-data" class="form-grid">
                        <label>
                            사진 업로드
                            <input type="file" name="photo" accept="image/jpeg,image/png,image/gif" required>
                        </label>
                        <div class="button-row">
                            <button class="primary" type="submit">사진 올리기</button>
                            <a class="button-link secondary" href="?action=logout">로그아웃</a>
                        </div>
                    </form>

                    <% if (success != null) { %>
                        <div class="success"><%= success %></div>
                    <% } %>
                    <% if (error != null) { %>
                        <div class="error"><%= error %></div>
                    <% } %>

                    <div>
                        <div class="section-title">기본 사진</div>
                        <div class="gallery">
                            <div class="photo-frame">
                                <img src="<%= request.getContextPath() %>/assets/photo-1.svg" alt="아침 햇살">
                                <div class="photo-label">아침 햇살</div>
                            </div>
                            <div class="photo-frame">
                                <img src="<%= request.getContextPath() %>/assets/photo-2.svg" alt="도시의 풍경">
                                <div class="photo-label">도시의 풍경</div>
                            </div>
                            <div class="photo-frame">
                                <img src="<%= request.getContextPath() %>/assets/photo-3.svg" alt="잔잔한 바닷가">
                                <div class="photo-label">잔잔한 바닷가</div>
                            </div>
                            <div class="photo-frame">
                                <img src="<%= request.getContextPath() %>/assets/photo-4.svg" alt="숲길 산책">
                                <div class="photo-label">숲길 산책</div>
                            </div>
                        </div>
                    </div>

                    <div>
                        <div class="section-title">업로드된 사진</div>
                        <% if (uploaded.isEmpty()) { %>
                            <div class="footer-note">아직 업로드된 사진이 없습니다. 사진을 올리면 이곳에 추가됩니다.</div>
                        <% } else { %>
                            <div class="upload-list">
                                <% for (String name : uploaded) { %>
                                    <div class="mini-card">
                                        <img src="<%= request.getContextPath() %>/image?name=<%= URLEncoder.encode(name, java.nio.charset.StandardCharsets.UTF_8) %>" alt="업로드 사진">
                                        <div class="photo-label"><%= name.substring(0, 8) %>...</div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                </div>
            <% } %>
        </section>
    </main>
</body>
</html>
