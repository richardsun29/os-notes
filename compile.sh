output="lecture6/index.html"
markdown="index.md"
css="style.css"

echo "<!DOCTYPE html>
<html>
<head>
<meta http-equiv='Content-Type' content='text/html;charset=UTF-8'>
<title>Lecture 6 - OS Organization Revisited</title>
<style>
$(cat $css)
</style>
</head>
<body>
$(pandoc --from markdown_github --to html $markdown)
</body>
</html>" > $output
