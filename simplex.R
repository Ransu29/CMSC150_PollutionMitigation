# finds the pivot column (most negative value in last row)
getPivotColumn <- function(finalTableu, nRows, nCols) {
  min = 0
  index = 0
  for (col in 1:(nCols - 1)) {
    current = finalTableu[nRows, col]
    if (current < min) {
      min = current
      index = col
    }
  }
  return(index)
}


#finds the pivot row using minimum ratio test
getPivotRow <- function(finalTableu, pivotColumn, nRows, nCols) {
  minimum = Inf
  index = 0
  for (row in 1:(nRows - 1)) {
    currentElement = finalTableu[row, pivotColumn]
    
    # skip if zero or negative
    if (currentElement <= 0) {
      next
    }
    
    # compute ratio (rhs / pivot column)
    currentValue = finalTableu[row, nCols] / currentElement
    
    # keep the smallest positive ratio
    if (currentValue > 0 && currentValue < minimum) {
      minimum = currentValue
      index = row
    }
  }
  return(index)
}


# gets the z (objective function) value from the tableau
getZ <- function(tableu) {
  nR = nrow(tableu)
  return(tableu[nR, ncol(tableu)])
}



GaussJordanSimplex <- function(tableu, isMax) {
  
  finalTableu = tableu
  nRows = nrow(tableu)
  nCols = ncol(tableu)
  valid = TRUE
  # for tracking iterations
  iterations = list(tableu) 
  
  # for tracking the basic solution at each step
  iterSolutions = list()
  # calculate and store the solution for the initial tableau 
  initial_solution = if (isMax) MaximizeData(tableu, nRows, nCols) else MinimizeData(tableu, nRows, nCols)
  iterSolutions[[1]] = initial_solution
  
  while (TRUE) {
    pivotColumn = getPivotColumn(finalTableu, nRows, nCols)
    
    if (pivotColumn == 0) {
      break 
    }
    
    pivotRow = getPivotRow(finalTableu, pivotColumn, nRows, nCols)
    
    if (pivotRow == 0) {
      warning("no valid pivot row found — solution is unbounded.")
      valid <- FALSE
      break 
    }
    
    pivotElement = finalTableu[pivotRow, pivotColumn]
    normalizedPivotRow = finalTableu[pivotRow, ] / pivotElement
    finalTableu[pivotRow, ] = normalizedPivotRow
    
    # elimination process
    for (row in 1:nRows) {
      if (row == pivotRow) next
      mult = finalTableu[row, pivotColumn]
      finalTableu[row, ] = finalTableu[row, ] - mult * normalizedPivotRow
    }
    
    # store the full tableau of the current iteration
    iterations[[length(iterations) + 1]] = finalTableu
    
    # calculate and store the basic solution for the current iteration ---
    current_solution <- if (isMax) MaximizeData(finalTableu, nRows, nCols) else MinimizeData(finalTableu, nRows, nCols)
    iterSolutions[[length(iterSolutions) + 1]] = current_solution
  }
  
  # return the new list along with the others
  return(list("finalTableau" = finalTableu, "iterations" = iterations, "iterSolutions" = iterSolutions, "valid" = valid))
}


# gets basic solution for maximization
MaximizeData <- function(finalTableu, nRows, nCols) {
  basicSolution = matrix(0, 1, nCols - 1)
  
  # find basic variables 
  for (col in 1:(nCols - 2)) {
    numOfNonZero = 0
    value = 0
    
    for (row in 1:nRows) {
      if (finalTableu[row, col] != 0) {
        numOfNonZero = numOfNonZero + 1
      }
      if (finalTableu[row, col] == 1) {
        value = finalTableu[row, nCols]
      }
      if (numOfNonZero > 1) {
        value = 0
        break
      }
    }
    basicSolution[1, col] = value
  }
  
  # get the z value
  basicSolution[1, nCols - 1] = getZ(finalTableu)
  
  # label columns only up to z
  colnames(basicSolution) = colnames(finalTableu)[1:(nCols - 1)]
  
  return(basicSolution)
}


# extracts the basic solution for minimization
MinimizeData <- function(finalTableu, nRows, nCols) {
  basicSolution = matrix(0, 1, nCols - 1)
  
  # variable values are taken from last row, per column
  for (col in 1:(nCols - 2)) {
    basicSolution[1, col] = finalTableu[nRows, col]
  }
  
  # z value is located at last row, last column
  basicSolution[1, nCols - 1] = finalTableu[nRows, nCols]
  
  # label columns only up to z
  colnames(basicSolution) = colnames(finalTableu)[1:(nCols - 1)]
  
  return(basicSolution)
}



Simplex <- function(tableu, isMax = TRUE) {
  nRows = nrow(tableu)
  nCols = ncol(tableu)
  
  # compute final tableau and capture all results
  eliminationsResults = GaussJordanSimplex(tableu, isMax) 
  
  finalTableau = eliminationsResults[["finalTableau"]]
  valid = eliminationsResults[["valid"]]
  iterations = eliminationsResults[["iterations"]]
  
  # capture the list of solutions using the correct name
  iterSolutions = eliminationsResults[["iterSolutions"]]
  
  # get the final basic solution (it's the last one in the list we just got)
  basicSolution = iterSolutions[[length(iterSolutions)]]
  
  # extract z value from the final solution
  Z = basicSolution[1, (nCols - 1)]
  
  # returns all the necessary information for the ui
  return(
    list(
      finalTableau = finalTableau, 
      iterations = iterations, 
      iterSolutions = iterSolutions, 
      basicSolution = basicSolution, 
      Z = Z, 
      valid = valid
    )
  )
}