require-module luar

define-command objetiva-line -docstring %{
    objetiva-line: select a line.
} %<
    lua %val{object_flags} %val{select_mode} %<
        local object_flags, select_mode = args()

        local to_begin, to_end = object_flags:find("to_begin"), object_flags:find("to_end")

        if select_mode == "extend" then
        	if to_end then
        		selector = "}"
        	else
        		selector = "{"
        	end

        elseif to_begin and to_end then
        	selector = "<a-a>"

        elseif to_begin then
        	selector = "["

        else
        	selector = "]"
    	end

    	local inner = object_flags:find("inner") and "_" or ""
    	local command = string.format([[execute-keys %sc^,\n<ret>%s]], selector, inner)
    	kak.evaluate_commands("-itersel", "try %{" .. command .. "}")
    >
>


define-command objetiva-case -docstring %{
    objetiva-case: select a segment of a word using either camel case, snake case or kebak case.
} %<
    lua %val{object_flags} %val{select_mode} %<
        local object_flags, select_mode = args()

        local to_begin = object_flags:find("to_begin")
        local to_end = object_flags:find("to_end")
        local inner = object_flags:find("inner") and true or false

        function operation()
            if select_mode == "extend" then
                if to_end then
                    return "}"
                end

                return "{"
            end

            if to_begin and to_end then
                return "<a-a>"
            end

            if to_begin then
                return "["
            end

            return "]"
        end

        kak.object_case_select(operation(), inner)
    >
>

# objetiva-case-select does the actual selection of a case segment. It receives
# as arguments the operation (<a-a>, ], {... ) and whether it's inner or not.
define-command objetiva-case-select -hidden -params 2 %(
    evaluate-commands -itersel -save-regs X %(
        # Select current word to determine its naming style
        execute-keys -draft <a-i>w"Xy

        lua %reg{X} %arg{1} %arg{2} %(
            local word, operation, inner = args()

            if word:find("_") then
            	-- Snake case
            	description = {
                	open = [[(?<lt>=_).|\b\w]],
                	close = inner and [[(?=[^_]_).|\b]] or [[_|\w\b]]
            	}

            elseif word:find("[A-Z]") then
            	-- Camel and pascal case
            	description = {
                	open = [[[A-Z]|\b\w]],
                	close = [[(?=[^A-Z][A-Z]).|\w\b]]
            	}

            else
            	-- Kebab case
            	description = {
                	open = [[\b\w]],
                	close = inner and [[\w\b]] or [[-|(?=[\-\w][^\-\w]).]]
            	}
            end

            kak.execute_keys(string.format("%sc%s,%s<ret>", operation, description.open, description.close))
        )
    )
)


define-command objetiva-case-move -docstring %{
    objetiva-case-move: select the next segment of a word using either camel case, snake case or kebab case.
} %{
    lua %val{count} %{
        local count = arg[1] == 0 and 1 or arg[1]

        for i = 1, count do
        	kak.execute_keys("-save-regs", "/", [[/\w<ret>]])
            kak.object_case_select("<a-a>", false)
    	end
    }
}


define-command objetiva-case-move-previous -docstring %{
    objetiva-case-move-previous: select the previous segment of a word using either camel case, snake case or kebab case.
} %{
    lua %val{count} %{
        local count = arg[1] == 0 and 1 or arg[1]

        for i = 1, count do
        	kak.execute_keys("-save-regs", "/", [[<a-/>\w<ret>]])
            kak.object_case_select("<a-a>", false)
    	end
    }
}


define-command objetiva-case-expand -docstring %{
    objetiva-case-expand: expand the selection to the next segment of a word using either camel case, snake case or kebab case.
} %{
    evaluate-commands -itersel -save-regs ^/ %{
        execute-keys -save-regs '' Z

        lua %val{count} %{
            local count = arg[1] == 0 and 1 or arg[1]

            for i = 1, count do
                kak.execute_keys([[/\w<ret>]])
                kak.object_case_select("<a-a>", false)
            end
        }

        execute-keys <a-z>u
    }
}

define-command objetiva-case-expand-previous -docstring %{
    objetiva-case-expand-previous: expand the selection to the previous segment of a word using either camel case, snake case or kebab case.
} %{
    evaluate-commands -itersel -save-regs ^/ %{
        execute-keys -save-regs '' Z

        lua %val{count} %{
            local count = arg[1] == 0 and 1 or arg[1]

            for i = 1, count do
                kak.execute_keys([[<a-/>\w<ret>]])
                kak.object_case_select("<a-a>", false)
            end
        }

        execute-keys <a-z>u<a-semicolon>
    }
}

define-command objetiva-matching -docstring %{
    objetiva-matching: select the text enclosed by matching characters. Like the m key, but as an object selection.
} %(
    lua "%opt{matching_pairs}" %val{object_flags} %val{select_mode} %(
        local matching_pairs, object_flags, select_mode = args()

        function parse_matching_pairs()
			local pairs = {}
			local count = 0

			for codepoint in matching_pairs:gmatch("%S+") do
				if count % 2 == 0 then
					if codepoint == "(" or codepoint == "[" or codepoint == "{" then
						codepoint = [[\]] .. codepoint

					elseif codepoint == "<" then
						codepoint = "<lt>"
					end

					pairs[#pairs + 1] = { open = codepoint }

				else
					if codepoint == ")" or codepoint == "]" or codepoint == "}" then
						codepoint = [[\]] .. codepoint
					end

					pairs[#pairs].close = codepoint
				end

				count = count + 1
			end

			return pairs
        end

        function operation()
            local to_begin = object_flags:find("to_begin")
            local to_end = object_flags:find("to_end")
            local inner = object_flags:find("inner")

            if select_mode == "extend" then
                if to_end then
                    return inner and "<a-}>" or "}"
                end

                return inner and "<a-{>" or "{"
            end

            if to_begin and to_end then
                return inner and "<a-i>" or "<a-a>"
            end

            if to_begin then
                return inner and "<a-[>" or "["
            end

            return inner and "<a-]>" or "]"
        end

    	function select_shortest(pairs, operation)
    		local commands = {}

    		for _, pair in ipairs(pairs) do
    			commands[#commands + 1] =
    				string.format("objetiva-matching-select-shortest %s %s %s", operation, pair.open, pair.close)
    		end

    		kak.object_matching_execute_all(table.concat(commands, "\n"))
    	end

		local pairs = parse_matching_pairs()
    	select_shortest(pairs, operation())
    )
)

# Selects the object based on the parameters, then tries to combine with
# previous mark.
#
# Parameters:
#     arg1: operation (like <a-a>, <a-i>...)
#     arg2: open codepoint
#     arg3: close codepoint
define-command objetiva-matching-select-shortest -hidden -params 3 %{
    try %{
        execute-keys -save-regs '' -draft "%arg{1}c%arg{2},%arg{3}<ret><a-z>-Z"
    } catch %{
        execute-keys -save-regs '' -draft "%arg{1}c%arg{2},%arg{3}<ret>Z"
    } catch ''
}

# Execute the provided commands preserving ^ register
define-command objetiva-matching-execute-all -hidden -params 1 %{
    evaluate-commands -save-regs ^ -itersel %{
        set-register ^
        evaluate-commands %arg{1}
        execute-keys z
    }
}
