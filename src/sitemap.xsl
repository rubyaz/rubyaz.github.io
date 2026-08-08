<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:s="http://www.sitemaps.org/schemas/sitemap/0.9">

  <xsl:output method="html" encoding="UTF-8" />

  <xsl:template match="/">
    <html>
      <head>
        <title>Sitemap — <xsl:value-of select="count(s:urlset/s:url)" /> URLs</title>
        <link href="https://fonts.googleapis.com/css2?family=Peralta&amp;display=swap" rel="stylesheet" />
        <link href="https://fonts.cdnfonts.com/css/national-park" rel="stylesheet" />
        <style>
          :root {
            --bg: #FDF9F7;
            --surface: #FFFFFF;
            --fg: #3E3B3A;
            --muted: #6B7280;
            --border: #E8E5E3;
            --accent: #D62744;
            --font-display: 'Peralta', serif;
            --font-body: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
            --font-mono: 'National Park', monospace;
          }
          body { font-family: var(--font-body); color: var(--fg); background: var(--bg); max-width: 960px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }
          h1 { font-family: var(--font-display); font-size: 2.5rem; margin-bottom: 0.25rem; font-weight: normal; color: #2B1046; }
          p { color: var(--muted); margin-bottom: 1.5rem; font-family: var(--font-mono); font-size: 13px; }
          table { width: 100%; border-collapse: collapse; background: var(--surface); box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
          th { text-align: left; border-bottom: 2px solid var(--accent); padding: 0.75rem 1rem; font-size: 0.85rem; color: var(--muted); font-family: var(--font-mono); text-transform: uppercase; letter-spacing: 0.05em; }
          td { border-bottom: 1px solid var(--border); padding: 0.75rem 1rem; font-size: 0.95rem; }
          a { color: var(--accent); text-decoration: none; }
          a:hover { text-decoration: underline; }
          tr:hover td { background: var(--bg); }
        </style>
      </head>
      <body>
        <h1>Ruby::AZ Sitemap</h1>
        <p><xsl:value-of select="count(s:urlset/s:url)" /> URLs</p>
        <table>
          <tr>
            <th>URL</th>
            <th>Last Modified</th>
          </tr>
          <xsl:for-each select="s:urlset/s:url">
            <tr>
              <td><a href="{s:loc}"><xsl:value-of select="s:loc" /></a></td>
              <td><xsl:value-of select="substring(s:lastmod, 1, 10)" /></td>
            </tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
