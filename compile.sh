output="lecture6/index.html"
> $output
echo '<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<title>Lecture 6 - OS Organization Revisited</title>
</head>
<body>' >>$output

pandoc --from markdown --to html index.md >> $output

echo '</body>
</html>' >> $output
