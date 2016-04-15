---
title: Github Pages Notes
category: Writing
tags: markdown github-pages kramdown gfm jekyll
---

*How meta!*

* [Current Versions of Dependencies](https://pages.github.com/versions/)
* [Kramdown Syntax](http://kramdown.gettalong.org/syntax.html)
* [Kramdown Quick Reference](http://kramdown.gettalong.org/quickref.html)
* [Supported languages for highlighting
    ](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml)
* [Liquid templates](https://github.com/Shopify/liquid/wiki)

* Links with text are always **\[bracket\]\(parentheses\)**. I don't know what I
have such a hard time remembering this.
*    To include a fenced code block within an element of a list, indent the block
to the same level as the first non-space character after the list marker.

     ```
  This works like this
     ```

     ```
     And it keeps going
     ```

   ```
   But a "normal" indent which does not match the indentation does not.
   ```

* The previous example's fenced code blocks also shows another feature: If the
code is aligned with the fence (i.e., \`\`\`) like "And it keeps going" is, then
the code is shown with no indentation. If, however, the code is indented
**more** *or* **less** like "This works like this" is, then the code is
indented.
* To choose "no layout", just use the following in the *frontmatter* YAML:

  ```
  ---
  layout:
  ---
  ```
