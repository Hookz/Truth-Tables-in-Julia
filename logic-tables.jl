# \wedge is ∧ and \vee is ∨ and \land is ∧ and \lor is ∨

¬(p::Bool) = !p
∧(p::Bool, q::Bool) = p && q
∨(p::Bool, q::Bool) = p || q
→(p::Bool, q::Bool) = (p ∧ q) || ¬p
↔(p::Bool, q::Bool) = (p→q)&&(q→p)

global ccount = 0

operators = Set([:¬, :∧, :∨, :→, :↔])
is_operator(x) = x in operators

function dissect_expression(expression)
    argument_symbols = Set{Symbol}()
    for symbol = expression.args
        if typeof(symbol) == Symbol
            if !is_operator(symbol)
                push!(argument_symbols, symbol)
            end
        elseif typeof(symbol) == Expr
            argument_symbols = union!(argument_symbols, dissect_expression(symbol))
        end
    end
    return argument_symbols
end

function eval_statement(statement)
    parameters = sort(collect(dissect_expression(statement)))
    sub_statements = reverse(find_exprs(statement))
    result = ""
    for param = parameters
        result*="\$$(param)\$ & "
        global ccount
        ccount+=1
	print("$(param)\t")
    end
    for i=1:length(sub_statements)-1
	sub = sub_statements[i]
	result *= "$(sub) & "
    	print("$(sub)\t")
    end
    print("$(statement)")
    result*="\$$(statement)\$\\\\\\hline\n"
    println()

    for i = 0:2^length(parameters) - 1
        digs = digits(i, base=2, pad=length(parameters))
        for j = 1:length(parameters)
            param = parameters[j]
            value = Bool(digs[j])
            eval(:($param = $value))
            if j == 1
		result*="$(value)\t"
	    else
		result*="& $(value) "
	    end
            print("$(value)\t")
        end
	for j=1:length(sub_statements)
	    sub=sub_statements[j]
	    result*="& $(eval(sub)) "
            print("$(eval(sub))\t")
	end
        result*="\\\\\n"
	println()
    end
    return result
end

function parse_input(input)
    input = replace(input, "and" => "∧")
    input = replace(input, "or" => "∨")
    while occursin("if ", input)
        input = replace(input, r"if (.*) then (.*)"=>s"\1 → \2")
    end
    while occursin(" implies ", input)
        input = replace(input, r"(.*) implies (.*)"=>s"\1 → \2")
    end
    while occursin("iff", input)
        input = replace(input, r"(.*) iff (.*)"=>s"\1 ↔ \2")
    end
    input = replace(input, "not "=>"¬")
    return input
end

function find_exprs(p)
    ex = []
    queue = []
    push!(queue, p)
    while length(queue)!=0
        for a = queue[1].args
            if typeof(a)==Expr
                push!(queue, a)
            end
        end
       push!(ex, popfirst!(queue))
    end
    return ex
end

if length(ARGS)==0
    print("Enter your expression: ")
    input=readline()
else
    input = ARGS[1]
end
st = Meta.parse(parse_input(input))
result = eval_statement(st)
result = replace(result, "¬" => "\\neg ")
result = replace(result, "∧"=>"\\land ")
result = replace(result, "∨"=>"\\lor ")
result = replace(result, "→"=>"\\rightarrow ")
result = replace(result, "↔"=>"\\leftrightarrow ")
result = string("\\begin{tabular}{","c "^ccount,"c}",result,"\\end{tabular}\n")
if length(ARGS)<=1
    filename="table"
else
    filename=ARGS[2]
end
open(filename, "w") do f
    write(f, result)
end


print("Succesfully saved to $filename")
