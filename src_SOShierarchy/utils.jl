get_cstrname_lower(cstrname::String) = cstrname*"_lo"
get_cstrname_upper(cstrname::String) = cstrname*"_hi"
get_cstrname_eq(cstrname::String) = cstrname*"_eq"

get_momentcstrname() = "moment_cstr"

function get_cstrname(cstrname::String, cstrtype::Symbol)
    if cstrtype == :eq
        return get_cstrname_eq(cstrname)
    elseif cstrtype == :ineqlo
        return get_cstrname_lower(cstrname)
    elseif cstrtype == :ineqhi
        return get_cstrname_upper(cstrname)
    else
        error("get_cstrname(): Unknown type $cstrtype.")
    end
end

function get_normalizedpoly(cstr::Constraint, cstrtype::Symbol)
    if cstrtype == :eq
        return cstr.p - cstr.lb
    elseif cstrtype == :ineqlo
        return cstr.p - cstr.lb
    elseif cstrtype == :ineqhi
        return cstr.ub - cstr.p
    else
        error("get_normalizedpoly(): Unhandeld type $cstrtype.")
    end
end

function get_pbcstrname(cstrname::String)
    if ismatch(r".+(\_lo|\_hi|\_eq)", cstrname)
        return cstrname[1:end-3]
    else 
        return cstrname
    end
end