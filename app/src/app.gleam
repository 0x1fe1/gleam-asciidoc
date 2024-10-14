import gleam/io
import gleam/list
import gleam/string
import file_streams/file_stream
import file_streams/text_encoding

pub fn main() {
	let filename = "src/big.asciidoc"
	let assert Ok(stream) = file_stream.open_read_text(filename, text_encoding.Unicode)

	let tokens = parse(stream, [])
	tokens |> list.each(io.debug)

	let assert Ok(Nil) = file_stream.close(stream)
}

pub type Token {
	Paragraph(String)
	Heading(Int, String)
	List(Int, ListKind, String)
	Variable(String, String) // name, value
	Code(String)
	Attributes(String)
	Block(List(String))
	Newline
	EOF
}
pub type ListKind {
	Enum // = . text = 1) text
	Item // = * text = -) text
}
pub type BlockKind {
	ParagraphBlock
	CodeBlock
}

pub fn parse(stream, tokens) {
	case file_stream.read_line(stream) {
		Ok(line) -> {
			let line = string.trim_right(line)
			let new_tokens = case line {
				"----" -> parse_block(stream, [], CodeBlock)
				_ -> [parse_line(line)]
			}
			parse(stream, [new_tokens, tokens] |> list.flatten)
		}
		_ -> [EOF, ..tokens] |> list.reverse
	}
}
fn parse_block(stream, tokens, kind) {
	case file_stream.read_line(stream) {
		Ok(line) -> {
			let line = string.trim_right(line)
			let new_tokens = case line, kind {
				"----", CodeBlock -> []
				_, CodeBlock -> [parse_line_code(line, True)]
				_, _ -> [parse_line(line)]
			}
			parse_block(stream, [new_tokens, tokens] |> list.flatten, kind)
		}
		_ -> tokens
	}
}

fn parse_line(line) {
	let line = string.trim_right(line)
	case line {
		"=" <> _ -> parse_line_heading(line, 0)
		"." <> _ -> parse_line_list(line, 0, Enum)
		"*" <> _ -> parse_line_list(line, 0, Item)
		":" <> _ -> parse_line_variable(line)
		"[" <> _ -> parse_line_attributes(line)
		" " <> _ | "\t" <> _ -> parse_line_code(line, False)
		"" -> Newline
		_ -> Paragraph(line)
	}
}

fn parse_line_heading(line, level) {
	case line {
		"=" <> _ -> parse_line_heading(string.drop_left(line, 1), level+1)
		_ -> Heading(level, line |> string.trim)
	}
}

fn parse_line_list(line, level, kind) {
	case line {
		"." <> _ | "*" <> _ -> parse_line_list(string.drop_left(line, 1), level+1, kind)
		_ -> List(level, kind, line |> string.trim)
	}
}

fn parse_line_variable(line) {
	let #(name, value) = parse_line_variable_name(line |> string.to_graphemes, "", False)
	Variable(name |> string.trim, value |> string.trim)
}
fn parse_line_variable_name(chars, name, name_started) {
	case chars, name_started {
		[":", ..rest], True -> #(name, rest |> string.concat)
		[":", ..rest], False -> parse_line_variable_name(rest, name, True)
		[x, ..rest], _ -> parse_line_variable_name(rest, name <> x, True)
		[], _ -> #(name, "")
	}
}

fn parse_line_code(line, is_block) {
	case is_block {
		True -> Code(line)
		False -> Code(line |> string.trim_left)
	}
}

fn parse_line_attributes(line) {
	line
	|> Attributes
}
