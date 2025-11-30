source("setup.R")
source("simplex.R")

# creates the cost summary table
getProjects<-function(basicSolution, chosenProjects){
  solutionItems = c()
  numOfItems = 0
  
  for(proj_name in chosenProjects){
    if(proj_name %in% colnames(basicSolution) && basicSolution[1, proj_name] > 1e-6){
      quantity = basicSolution[1, proj_name]
      costs = projects_matrix[proj_name, "Costs"] * quantity
      solutionItems = c(solutionItems, proj_name, quantity, costs)
      numOfItems = numOfItems + 1
    }
  }
  
  total_col_name <- intersect(c("RHS", "Z"), colnames(basicSolution))
  totalCost <- basicSolution[1, total_col_name]
  
  solutionItems = c(solutionItems, "", "TOTAL:", totalCost)
  
  if (numOfItems == 0) {
    summary <- matrix(c("", "TOTAL:", totalCost), nrow = 1, ncol = 3)
  } else {
    summary <- matrix(solutionItems, nrow = (numOfItems+1), ncol = 3, byrow = TRUE)
  }
  
  colnames(summary) = c("Project", "Quantity", "Cost")
  return(summary)
}

# calculate total pollutant reduction
getPollutantSummary <- function(basicSolution, chosenProjects) {
  # store totals with names of pollutants
  total_reductions <- setNames(rep(0, length(pollutant_names)), pollutant_names)
  
  # loop through the projects that are in the optimal solution
  for(proj_name in chosenProjects){
    if(proj_name %in% colnames(basicSolution) && basicSolution[1, proj_name] > 1e-6){
      quantity <- basicSolution[1, proj_name]
      # get the vector of reductions per unit for this project
      reductions_per_unit <- projects_matrix[proj_name, pollutant_names]
      # add the total reduction for this project to our running total
      total_reductions <- total_reductions + (quantity * reductions_per_unit)
    }
  }
  
  # create a final data frame for display, including the targets for context
  summary_df <- data.frame(
    Pollutant = pollutant_names,
    `Total Reduction` = total_reductions,
    `Target` = pollutant_targets[pollutant_names], # ensure order is correct
    check.names = FALSE
  )
  
  return(summary_df)
}


# main function 
Solution <- function(chosenProjects) {
  #setup the tableau
  tableau = SetUpTableu(chosenProjects)
  initialTableau = tableau$setUpTableau
  #solves the tableau
  simplex = Simplex(initialTableau, FALSE)
  
  # returns if not valid
  if (!isTRUE(simplex$valid)) {
    return(
      list(
        initial = initialTableau,
        iterations = simplex$iterations,
        finalTableau = simplex$finalTableau,
        basicSolution = NULL, 
        iterSolutions = simplex$iterSolutions,
        summary = "the problem is infeasible or unbounded.",
        valid = FALSE
      )
    )
  }
  
  # if valid, generate both the cost and pollutant summaries
  costSummary = getProjects(simplex$basicSolution, chosenProjects)
  pollutantSummary = getPollutantSummary(simplex$basicSolution, chosenProjects)
  
  return(
    list(
      initial = initialTableau,
      iterations = simplex$iterations,
      finalTableau = simplex$finalTableau,
      basicSolution = simplex$basicSolution,
      iterSolutions = simplex$iterSolutions,
      summary = costSummary,
      pollutantSummary = pollutantSummary, 
      Z = simplex$Z,
      valid = TRUE
    )
  )
}