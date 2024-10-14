import gleam/io
import gleam/list
import gleam/string
import file_streams/file_stream
import file_streams/text_encoding

pub fn main() {
	let filename = "src/small.asciidoc"
	let assert Ok(stream) = file_stream.open_read_text(filename, text_encoding.Unicode)

	let lines = get_lines(stream)
	lines |> list.each(io.debug)

	let tokens = parse(lines)
	tokens |> list.each(io.debug)

	let assert Ok(Nil) = file_stream.close(stream)
}

pub fn get_lines(stream) {
	get_lines_helper(stream, []) |> list.reverse
}
pub fn get_lines_helper(stream, lines) {
	case file_stream.read_line(stream) {
		Ok(line) -> get_lines_helper(stream, [line, ..lines])
		Error(_) -> lines
	}
}

pub type Token {
	Paragraph(String)
	Heading(Int, String)
	List(ListKind, Int, String)
	Variable(String, String) // name, value
	Code(String)
	Attributes(String)
	Block(List(String))
	Newline
	Eof
}
pub type ListKind {
	Enum // . text  <=>  1) text
	Item // * text  <=>  -) text
}

pub fn parse(lines) {
	parse_helper(lines, []) |> list.reverse
}

fn parse_helper(lines, tokens) {
	case lines {
		[line, ..rest] -> {
			let line = string.trim_right(line)
			let #(new_tokens, rest_lines) = case line {
				"----" -> parse_block_code(rest, [])
				"" -> parse_block_paragraph(rest, [Newline])
				_ -> #([parse_line(line)], rest)
			}
			parse_helper(rest_lines, [new_tokens, tokens] |> list.flatten)
		}
		[] -> [Eof, ..tokens]
	}
}
fn parse_block_code(lines, tokens) {
	case lines {
		[line, ..rest] -> {
			let line = string.trim_right(line)
			let #(new_tokens, continue) = case line {
				"----" -> #([], False)
				_ -> #([parse_line_code(line, True)], True)
			}
			case continue {
				True -> parse_block_code(rest, [new_tokens, tokens] |> list.flatten)
				False -> #([new_tokens, tokens] |> list.flatten, rest)
			}
		}
		[] -> #(tokens, lines)
	}
}
fn parse_block_paragraph(lines, tokens) {
	case lines {
		[line, ..rest] -> {
			let line = string.trim_right(line)
			let #(new_tokens, continue) = case line {
				"" -> #([Newline], False)
				_ -> #([parse_line(line)], True)
			}
			case continue {
				True -> parse_block_paragraph(rest, [new_tokens, tokens] |> list.flatten)
				False -> #([new_tokens, tokens] |> list.flatten, rest)
			}
		}
		[] -> #(tokens, lines)
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
		_ -> List(kind, level, line |> string.trim)
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
