package gallery;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ImageServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private Path uploadDir() {
        return Paths.get(System.getProperty("catalina.base"), "webapps", "ROOT", "WEB-INF", "uploads");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (request.getSession(false) == null || !Boolean.TRUE.equals(request.getSession(false).getAttribute("loggedIn"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String name = request.getParameter("name");
        if (!isAllowedName(name)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        Path root = uploadDir();
        Path file = root.resolve(name).normalize();
        if (!file.startsWith(root) || !Files.isRegularFile(file)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String lower = name.toLowerCase(Locale.ROOT);
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            response.setContentType("image/jpeg");
        } else if (lower.endsWith(".png")) {
            response.setContentType("image/png");
        } else {
            response.setContentType("image/gif");
        }
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Content-Disposition", "inline; filename=\"" + name + "\"");

        try (OutputStream out = response.getOutputStream()) {
            Files.copy(file, out);
        }
    }

    private boolean isAllowedName(String name) {
        int dot = name == null ? -1 : name.lastIndexOf('.');
        if (dot != 32 || name.length() <= dot + 1) {
            return false;
        }
        for (int i = 0; i < dot; i++) {
            char c = name.charAt(i);
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) {
                return false;
            }
        }
        String ext = name.substring(dot + 1).toLowerCase(Locale.ROOT);
        return ext.equals("jpg") || ext.equals("jpeg") || ext.equals("png") || ext.equals("gif");
    }
}
