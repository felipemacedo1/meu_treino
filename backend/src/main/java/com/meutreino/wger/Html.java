package com.meutreino.wger;

import java.util.regex.Pattern;

/** Converte as descricoes HTML do wger em texto limpo. */
final class Html {

    private static final Pattern TAGS = Pattern.compile("<[^>]+>");
    private static final Pattern SPACES = Pattern.compile("[ \\t]+");
    private static final Pattern BLANK_LINES = Pattern.compile("\\n{3,}");

    private Html() {
    }

    static String toPlainText(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String text = raw
                .replace("</p>", "\n")
                .replace("<br>", "\n")
                .replace("<br/>", "\n")
                .replace("<br />", "\n")
                .replace("</li>", "\n")
                .replace("<li>", "- ");
        text = TAGS.matcher(text).replaceAll("");
        text = text
                .replace("&nbsp;", " ")
                .replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", "\"")
                .replace("&#39;", "'");
        text = SPACES.matcher(text).replaceAll(" ");
        text = BLANK_LINES.matcher(text).replaceAll("\n\n");
        text = text.lines().map(String::strip).reduce("", (a, b) -> a.isEmpty() ? b : a + "\n" + b);
        return text.isBlank() ? null : text.strip();
    }
}
