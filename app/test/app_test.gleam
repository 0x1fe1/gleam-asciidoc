import gleeunit
import gleeunit/should
import app

pub fn main() {
	gleeunit.main()
}

pub fn heading_test() {
	[
		"= Heading 1	",
		"== Heading 2    ",
		"=== Heading 3     	"
	]
	|> app.parse
	|> should.equal([
		app.Heading(1, "Heading 1"),
		app.Heading(2, "Heading 2"),
		app.Heading(3, "Heading 3"),
		app.Eof
	])
}

pub fn code_block_test() {
	[
		"[,c]",
		"----\n",
		"#include <stdio.h>\n",
		"\n",
		"int main() {\n",
		"	printf(\"windows sux\");\n",
		"}\n"
	]
	|> app.parse
	|> should.equal([
		app.Attributes("[,c]"),
		app.Code("#include <stdio.h>"),
		app.Code(""),
		app.Code("int main() {"),
		app.Code("\tprintf(\"windows sux\");"),
		app.Code("}"),
		app.Eof
	])
}

pub fn list_test() {
	[
		"* Unordered list item\n",
		"** Add another marker to make a nested item\n",
		"\n",
		". Another unordered list item (1)\n",
		".. Another unordered list item (2)\n",
		"... Another unordered list item (3)\n",
	]
	|> app.parse
	|> should.equal([
		app.List(app.Item, 1, "Unordered list item"),
		app.List(app.Item, 2, "Add another marker to make a nested item"),
		app.Newline,
		app.List(app.Enum, 1, "Another unordered list item (1)"),
		app.List(app.Enum, 2, "Another unordered list item (2)"),
		app.List(app.Enum, 3, "Another unordered list item (3)"),
		app.Eof
	])
}

pub fn attributes_test() {
	[
		"Doc Writer\n",
		"\n",
		":keywords: comparison, sample\n",
		":url-gitlab: https://gitlab.eclipse.org\n",
		":empty-var:\n",
	]
	|> app.parse
	|> should.equal([
		app.Paragraph("Doc Writer"),
		app.Newline,
		app.Variable("keywords", "comparison, sample"),
		app.Variable("url-gitlab", "https://gitlab.eclipse.org"),
		app.Variable("empty-var", ""),
		app.Eof
	])
}

pub fn complex_test() {
	[
		"= Document Title\n",
		"\n",
		"Doc Writer\n",
		"\n",
		":keywords: comparison, sample\n",
		":url-gitlab: https://gitlab.eclipse.org\n",
		":empty-var:\n",
		"\n",
		"\n",
		"\n",
		"A paragraph with *bold* and _italic_ text.\n",
		"A link to https://eclipse.org[Eclipse].\n",
		"A reusable link to {url-gitlab}[GitLab].\n",
		"\n",
		"image::an-image.jpg[An image,800]\n",
		"\n",
		"== Section title\n",
		"\n",
		"\n",
		"\n",
		"* Unordered list item\n",
		"** Add another marker to make a nested item\n",
		"\n",
		". Ordered list item\n",
		".. Another ordered list item\n",
		"\n",
		"NOTE: One of five built-in admonition block types.\n",
		"\n",
		"=== Subsection title\n",
		"\n",
		" Text indented by one space is preformatted.\n",
		"	Text indented by one tab is preformatted.\n",
		"\n",
		"A source block with a Ruby function named `hello` that prints \"`Hello, World!`\":\n",
		"\n",
		"[,ruby]\n",
		"----\n",
		"def hello name = 'World'\n",
		"  puts \"Hello, #{name}!\"\n",
		"end\n",
		"----\n",
	]
	|> app.parse
	|> should.equal([
		app.Heading(1, "Document Title"),
		app.Newline,
		app.Paragraph("Doc Writer"),
		app.Newline,
		app.Variable("keywords", "comparison, sample"),
		app.Variable("url-gitlab", "https://gitlab.eclipse.org"),
		app.Variable("empty-var", ""),
		app.Newline,
		app.Newline,
		app.Newline,
		app.Paragraph("A paragraph with *bold* and _italic_ text."),
		app.Paragraph("A link to https://eclipse.org[Eclipse]."),
		app.Paragraph("A reusable link to {url-gitlab}[GitLab]."),
		app.Newline,
		app.Paragraph("image::an-image.jpg[An image,800]"),
		app.Newline,
		app.Heading(2, "Section title"),
		app.Newline,
		app.Newline,
		app.Newline,
		app.List(app.Item, 1, "Unordered list item"),
		app.List(app.Item, 2, "Add another marker to make a nested item"),
		app.Newline,
		app.List(app.Enum, 1, "Ordered list item"),
		app.List(app.Enum, 2, "Another ordered list item"),
		app.Newline,
		app.Paragraph("NOTE: One of five built-in admonition block types."),
		app.Newline,
		app.Heading(3, "Subsection title"),
		app.Newline,
		app.Code("Text indented by one space is preformatted."),
		app.Code("Text indented by one tab is preformatted."),
		app.Newline,
		app.Paragraph("A source block with a Ruby function named `hello` that prints \"`Hello, World!`\":"),
		app.Newline,
		app.Attributes("[,ruby]"),
		app.Code("def hello name = 'World'"),
		app.Code("  puts \"Hello, #{name}!\""),
		app.Code("end"),
		app.Eof
	])
}
