ROOT = pwd()
include(joinpath(ROOT, "src_SOShierarchy", "SOShierarchy.jl"))


function main()

    ########################################
    # Construction du problème type
    rawproblem = buildPOP_1v1c()
    # rawproblem = buildPOP_1v2c()
    # rawproblem = buildPOP_2v3c()
    # rawproblem = buildPOP_WB2()

    ########################################
    # Normalizing pb and setting relaxation order by constraint
    problem = normalize_problem(rawproblem)
    relax_ctx = set_relaxation(problem, issparse = false, ismultiordered = false, d = 2)

    println(relax_ctx)

    println("\n")

    println(problem)

    ########################################
    # Construction du sparsity pattern, extension chordale, cliques maximales.
    sparsity_pattern, max_cliques, varsbycstr, cliquevarsbycstr, orderbyclique = build_sparsity(relax_ctx, problem)
    
    ########################################
    # Calcul des matrices B_i et pose du probleme
    momentmatrices = compute_momentmat(problem, max_cliques, cliquevarsbycstr, orderbyclique, relax_ctx)

    println("-------------------- momentmatrices:")
    for (cstr, mm) in momentmatrices
        println("$cstr :")
        println(mm)
    end
    println("--------------------")
    


    # B_i = compute_Bibycstr(problem, momentmatrices, max_cliques, cliquevarsbycstr, orderbyclique, relax_ctx)
    
    # SDP_SOS = build_SDP_SOS(problem, max_cliques, B_i, cliquevarsbycstr, orderbyclique, relax_ctx)
    
    # ########################################
    # # Calcul d'une solution par un solveur
    # m, Zi, yα_re, yα_im, expo2int, int2expo = make_JuMPproblem(SDP_SOS, SCSSolver(max_iters=5000000, eps=1e-3, verbose=true), relax_ctx)

    # println("-----> SDP_SOS problem size: ", Base.summarysize(m)/1024, " ko")
    # println("-----> JuMP problem size: ", Base.summarysize(m)/1024, " ko")

    # ########################################
    # # Résolution du SDP par un solveur
    # println("-----> Starting solve")
    # solve(m)

    # println("\n-----> Objective value: ", getobjectivevalue(m), "\n")

    # # for (cstrname, mmb) in B_i
    # #     println("$cstrname \t= ", getvalue(Zi[cstrname]), "\n")
    # # end

    # println("\n\n----->Lagrange multipliers : yα =")
    # yα = - getdual(yα_re) - im*getdual(yα_im)
    # print_cmat(yα)

end

main()