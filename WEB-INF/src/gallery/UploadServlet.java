package gallery;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.UUID;
import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

public class UploadServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final long MAX_PIXELS = 25_000_000L;

    private Path uploadDir() {
        return Paths.get(System.getProperty("catalina.base"), "webapps", "ROOT", "WEB-INF", "uploads");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (request.getSession(false) == null || !Boolean.TRUE.equals(request.getSession(false).getAttribute("loggedIn"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        Part part = request.getPart("photo");
        if (part == null || part.getSize() == 0) {
            request.getSession().setAttribute("error", "업로드할 사진을 선택해 주세요.");
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        if (part.getSize() > 5L * 1024 * 1024) {
            request.getSession().setAttribute("error", "사진은 5MB 이하만 업로드할 수 있습니다.");
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        String contentType = part.getContentType();
        boolean allowedType = "image/jpeg".equalsIgnoreCase(contentType)
            || "image/png".equalsIgnoreCase(contentType)
            || "image/gif".equalsIgnoreCase(contentType);
        if (!allowedType) {
            request.getSession().setAttribute("error", "JPG, PNG, GIF 형식의 사진만 허용됩니다.");
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        Path dir = uploadDir();
        Files.createDirectories(dir);

        String id = UUID.randomUUID().toString().replace("-", "");
        Path temp = Files.createTempFile(dir, id + "-", ".bin");
        try (InputStream in = part.getInputStream()) {
            Files.copy(in, temp, StandardCopyOption.REPLACE_EXISTING);
        }

        BufferedImage image = ImageIO.read(temp.toFile());
        if (image == null) {
            Files.deleteIfExists(temp);
            request.getSession().setAttribute("error", "이미지 파일만 업로드할 수 있습니다.");
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        if ((long) image.getWidth() * (long) image.getHeight() > MAX_PIXELS) {
            Files.deleteIfExists(temp);
            request.getSession().setAttribute("error", "이미지가 너무 큽니다.");
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        String format = detectFormat(contentType);
        if (format == null) {
            Files.deleteIfExists(temp);
            request.getSession().setAttribute("error", "지원하지 않는 이미지 형식입니다.");
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        Path target = dir.resolve(id + "." + format);
        Files.move(temp, target, StandardCopyOption.REPLACE_EXISTING);

        request.getSession().setAttribute("success", "사진이 업로드되었습니다.");
        response.sendRedirect(request.getContextPath() + "/");
    }

    private String detectFormat(String contentType) {
        if (contentType == null) {
            return null;
        }
        String type = contentType.toLowerCase(Locale.ROOT);
        if (type.contains("jpeg")) {
            return "jpg";
        }
        if (type.contains("png")) {
            return "png";
        }
        if (type.contains("gif")) {
            return "gif";
        }
        return null;
    }
}
