using AcademicCV
using Test
using YAML

@testset "AcademicCV.jl" begin
    # Create temporary test directories
    test_dir = mktempdir()
    data_dir = joinpath(test_dir, "_data")
    template_dir = joinpath(test_dir, "templates")
    output_dir = joinpath(test_dir, "output")
    
    mkpath(data_dir)
    mkpath(template_dir)
    
    # Create test YAML files
    @testset "YAML Data Loading" begin
        # Create test positions file
        positions_data = [
            Dict("position" => "Professor", "institution" => "University", 
                 "start_date" => "2020", "end_date" => "Present")
        ]
        YAML.write_file(joinpath(data_dir, "positions.yml"), positions_data)
        
        # Create test education file
        education_data = [
            Dict("degree" => "Ph.D.", "institution" => "Tech University", "year" => "2018")
        ]
        YAML.write_file(joinpath(data_dir, "education.yml"), education_data)
        
        # Test loading data
        data = load_data(data_dir)
        @test haskey(data, "positions")
        @test haskey(data, "education")
        @test length(data["positions"]) == 1
        @test data["positions"][1]["position"] == "Professor"
    end
    
    @testset "LaTeX Generation" begin
        # Create a simple template
        template_content = """
        \\documentclass{article}
        \\begin{document}
        {{#positions}}
        {{position}} at {{institution}}
        {{/positions}}
        \\end{document}
        """
        template_file = joinpath(template_dir, "test_template.tex")
        write(template_file, template_content)
        
        # Create test data
        test_data = Dict(
            "positions" => [
                Dict("position" => "Professor", "institution" => "University")
            ]
        )
        
        # Generate LaTeX
        output_file = joinpath(output_dir, "test.tex")
        mkpath(output_dir)
        generate_latex(test_data, template_file, output_file)
        
        @test isfile(output_file)
        output_content = read(output_file, String)
        @test occursin("Professor at University", output_content)
    end
    
    @testset "Error Handling" begin
        # Test with non-existent directory
        @test_throws ErrorException load_data("/nonexistent/directory")
        
        # Test with non-existent template
        @test_throws ErrorException generate_latex(Dict(), "/nonexistent/template.tex", "output.tex")
    end
    
    # Clean up
    rm(test_dir, recursive=true)
end
