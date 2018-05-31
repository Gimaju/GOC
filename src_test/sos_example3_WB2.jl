using Base.Test
ROOT = pwd()
include(joinpath("..", "src_SOShierarchy", "SOShierarchy.jl"))


## Application of the Moment–SOS Approach to Global Optimization of the OPF Problem
# C. Josz, J. Maeght, P. Panciatici, and J. Ch. Gilbert
# https://arxiv.org/pdf/1311.6370.pdf
# Data from table 1, p. 11.

@testset "WB2 real formulation - order 1" begin
    sols = SortedDict(0.976 => (2, 905.76, 905.76),
                      0.983 => (2, 905.73, 903.12),
                      0.989 => (2, 905.73, 900.84),
                      0.996 => (2, 905.73, 898.17),
                      1.002 => (2, 905.73, 895.86),
                      1.009 => (2, 905.73, 893.16),
                      1.015 => (2, 905.73, 890.82),
                      1.022 => (3, 905.73, 888.08),
                      1.028 => (3, 905.73, 885.71),
                      1.035 => (2, 882.97, 882.97))

    testfolder = joinpath("Mosek_runs", "tests")
    @testset "v2max=$v2max, rmeqs=$rmeqs" for (v2max, (dmax, obj_fixedphase, obj_rankrel)) in sols, rmeqs in Set([true, false])

        # info("Working on WB2, no eqs, v2max=$v2max, d=$d")
        problem = buildPOP_WB2(v2max=v2max, rmeqs=rmeqs)

        logpath = joinpath(testfolder, "WB2_v2max_$(v2max)_rankrel")
        ispath(logpath) && rm(logpath, recursive=true); mkpath(logpath)
        println("Saving file at $logpath")

        relax_ctx = set_relaxation(problem; hierarchykind=:Real,
                                            d = 1)

        primobj, dualobj = run_hierarchy(problem, relax_ctx, logpath, save_pbs=true);
        @test primobj ≈ obj_rankrel atol=1e-2
        @test dualobj ≈ obj_rankrel atol=1e-2
    end
end

@testset "WB2 real formulation, fixed phase" begin
    sols = SortedDict(0.976 => (2, 905.76, 905.76),
                    0.983 => (2, 905.73, 903.12),
                    0.989 => (2, 905.73, 900.84),
                    0.996 => (2, 905.73, 898.17),
                    1.002 => (2, 905.73, 895.86),
                    1.009 => (2, 905.73, 893.16),
                    1.015 => (2, 905.73, 890.82),
                    1.022 => (3, 905.73, 888.08),
                    1.028 => (3, 905.73, 885.71),
                    1.035 => (2, 882.97, 882.97))

    testfolder = joinpath("Mosek_runs", "tests")
    @testset "v2max=$v2max, rmeqs=$rmeqs, addball=$addball" for (v2max, (dmax, obj_fixedphase, obj_rankrel)) in sols, rmeqs in Set([true, false]), addball in Set([true, false])

        # info("Working on WB2, no eqs, v2max=$v2max, d=$d")
        problem = buildPOP_WB2(v2max=v2max, rmeqs=rmeqs, setnetworkphase=true, addball=addball)

        logpath = joinpath(testfolder, "WB2_v2max_$(v2max)_rankrel")
        ispath(logpath) && rm(logpath, recursive=true); mkpath(logpath)
        println("Saving file at $logpath")

        relax_ctx = set_relaxation(problem; hierarchykind=:Real,
                                            d = dmax)

        primobj, dualobj = run_hierarchy(problem, relax_ctx, logpath, save_pbs=true);
        @show primobj, dualobj, obj_fixedphase
        @test primobj ≈ obj_fixedphase atol=1e-2
        @test dualobj ≈ obj_fixedphase atol=1e-2
    end
end