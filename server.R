# server.R 

# load required libraries
library(shiny)          # ui library
library(bslib)          # boostrap ui lib
library(shinyWidgets)   # widget lib
library(ggplot2)        # for data visualization
library(thematic)       # for graph styling
library(scales)         # for displaying currency values

# enable auto theming for plots to match bslib themes
thematic_shiny(font = "auto")

# source helper and logic files
source("setup.R")
source("simplex.R")
source("solution.R")



#server functions
function(input, output, session) {
  
  # fill the project selection checkbox on app 
  updateCheckboxGroupInput(session, "chosen_projects",
                           choices = project_full_names,
                           selected = project_full_names[1:6]
  )
  
  # create a reactive storage for the results of the simplex algorithm
  # allows different parts of the ui to react to the same calculated data
  solution_data <- reactiveValues(result = NULL)
  
  
  # sidebar event handlers 
  
  # handler for the 'select all' button
  observeEvent(input$choose_all, {
    updateCheckboxGroupInput(session, "chosen_projects", selected = project_full_names)
  })
  
  # handler for the "clear all" button
  observeEvent(input$clear_all, {
    updateCheckboxGroupInput(session, "chosen_projects", selected = character(0))
  })
  
  
  # initial tableau rendering
  # table updates reactively whenever the user changes their project selection
  output$live_initial_tableau <- renderTable({
    # req() ensures that this code only runs if at least one project is selected
    req(input$chosen_projects)
    SetUpTableu(input$chosen_projects)$setUpTableau
  }, rownames = TRUE, digits = 2)
  
  
  # core optimization logic
  
  # event trigger when the user clicks the "optimize cost" button
  observeEvent(input$run_simplex, {
    # validate that at least one project is selected before running
    if (is.null(input$chosen_projects) || length(input$chosen_projects) == 0) {
      showNotification("Please select at least one project.", type = "warning")
      return()
    }
    
    # show loading indicator to the user when calculating
    withProgress(message = 'running simplex algorithm...', value = 0.5, {
      # call the main solver function from solution.r and store the entire result
      solution_data$result <- Solution(input$chosen_projects)
    })
    
    # provide user feedback notifications based on the validity
    if (isTRUE(solution_data$result$valid)) {
      showNotification("Optimization successful!", type = "message")
    } else {
      showNotification("Optimization failed. problem may be infeasible.", type = "error")
    }
  })
  
  
  # dynamic ui for displaying results with rearranged cards
  # builds the ui for the results section
  # appears only after the optimization has run
  output$results_ui <- renderUI({
    # appears after a calculation has run
    req(solution_data$result)
    optimization_result <- solution_data$result
    
    # handle the case where the solution is infeasible
    if (!isTRUE(optimization_result$valid)) {
      return(
        card(class = "mt-3", card_header(class = "bg-danger text-white", "infeasible solution"),
             card_body(p(strong("reason:"), optimization_result$summary), hr(), h5("Final Tableau:"),
                       div(style="overflow-x:auto;", renderTable(optimization_result$finalTableau, rownames=TRUE, digits=2))))
      )
    }
    
    # if valid, build a set of cards to display all results
    number_of_iterations <- max(0, length(optimization_result$iterations) - 1)
    tagList(
      # shows the final basic solution table (moved up)
      card(class = "mt-3", card_header("Final Basic Solution"),
           card_body(
             p("This table shows the values of all variables at the final optimal state."),
             div(style = "overflow-x:auto;", tableOutput("final_solution_table"))
           )
      ),
      
      # holds both the cost and pollutant summaries
      card(class = "mt-3",
           card_header(class = "bg-success text-white",
                       div("Optimal Solution Summary", span(class = "badge bg-light text-success ms-2", paste(number_of_iterations, "iterations"))),
                       actionButton("show_solution_steps", "View Steps", icon = icon("magnifying-glass"), class = "btn-light btn-sm"),
                       style = "display:flex; align-items: center; justify-content: space-between;"),
           card_body(
             h4(paste("Total Optimal Cost:", dollar(optimization_result$Z, accuracy=0.01))),
             hr(),
             h5("Summary of Recommended Projects:"), 
             tableOutput("summary_table")
             
           )
      ),
      
      # displays the visualization plot
      card(class = "mt-3", card_header("Allocation Visualization", class = "bg-info text-white"),
           card_body(plotOutput("results_plot", height = "500px"))),
      card(class="mt-3", card_header("Total Pollutant Reduction", class = "bg-info text-white"),
          card_body(p("The total amount of each pollutant reduced by the optimal project mix."),
                    tableOutput("pollutant_summary_table"))
           )
    )
  })
  
  
  # output renderers for the results ui ===========================================================
  
  # renders the main cost summary table
  output$summary_table <- renderTable({
    req(solution_data$result$summary)
    summary_df <- as.data.frame(solution_data$result$summary)
    colnames(summary_df) <- c("Project", "Units", "Cost ($)")
    summary_df
  }, rownames = FALSE, digits = 2)
  
  # renders the pollutant reduction summary table
  output$pollutant_summary_table <- renderTable({
    req(solution_data$result$pollutantSummary)
    solution_data$result$pollutantSummary
  }, rownames = FALSE, digits = 2)
  
  # renders the final basic solution table.
  output$final_solution_table <- renderTable({
    req(solution_data$result$basicSolution)
    solution_data$result$basicSolution
  }, rownames = FALSE, digits = 4)
  
  #renders the ggplot visualization of the project costs
  output$results_plot <- renderPlot({
    req(solution_data$result$summary)
    
    #prepare data for plotting
    cost_summary_df = as.data.frame(solution_data$result$summary)
    colnames(cost_summary_df) = c("Project", "Units", "Cost")
    
    
    # the total row is identified by having an empty string "" in the project column
    plot_data = cost_summary_df[cost_summary_df$Project != "", ]
    
    #convert to numeric
    plot_data$Units <- as.numeric(plot_data$Units)
    plot_data$Cost <- as.numeric(plot_data$Cost)
    
    # filter out any remaining projects with zero units
    plot_data <- plot_data[plot_data$Units > 0.01, ]
    if(nrow(plot_data) == 0) return(NULL) #return nothing if no projects have units > 0
    
    # create a formatted text label for each bar
    plot_data$labelText <- paste0(round(plot_data$Units, 2), " Units | ", dollar(plot_data$Cost))
    
    # adjust text color for light/dark theme modes
    is_dark_mode <- isTRUE(input$theme_mode == "dark")
    text_color <- if(is_dark_mode) "white" else "black"
    
    # generate the plot using ggplot2
    ggplot(plot_data, aes(x = reorder(Project, Units), y = Units, fill = Cost)) +
      geom_col(width = 0.7) + 
      geom_text(aes(label = labelText), hjust = -0.1, fontface = "bold", size = 5, color = text_color) +
      scale_fill_gradient(low = "#69b3a2", high = "#404080", labels = dollar_format()) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.55))) + #give space for text labels
      coord_flip() + #create a horizontal bar chart
      labs(x = NULL, y = "Number of Units", fill = "Total Cost") +
      theme_minimal(base_size = 16) +
      theme(
        panel.grid.major.y = element_blank(), 
        panel.grid.minor = element_blank(), 
        axis.title = element_text(color = text_color),   
        axis.text.y = element_text(face = "bold", color = text_color), 
        axis.text.x = element_text(color = text_color), 
        legend.text = element_text(color = text_color), 
        legend.title = element_text(color = text_color),
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA),
        legend.background = element_rect(fill = "transparent", color = NA)
      )
  }, bg = "transparent") 
  
  
  # modal dialog for viewing iterations =======================================================
  
  # triggers when the "view steps" button is clicked
  observeEvent(input$show_solution_steps, {
    req(solution_data$result, isTRUE(solution_data$result$valid))
    optimization_result = solution_data$result
    number_of_iterations = length(optimization_result$iterations)
    
    # create labels for the radio buttons
    iteration_step_labels = c("Initial Setup", paste("Iteration", 1:(number_of_iterations-1)))
    
    #build and display the modal dialog
    showModal(modalDialog(
      title = "Simplex Algorithm Iterations", size = "xl",
      layout_sidebar(fillable = TRUE,
                     sidebar = sidebar(title = "History", width = 250,
                                       radioButtons("selected_iter_idx", "Select state:", 
                                                    choiceNames = iteration_step_labels,
                                                    choiceValues = 1:number_of_iterations, selected = number_of_iterations)),
                     card(card_header(textOutput("modal_iter_title")),
                          card_body(
                            h5("Tableau"),
                            div(style = "overflow-x: auto;", tableOutput("modal_iter_table")),
                            hr(),
                            h5("Basic Solution for this step"),
                            div(style = "overflow-x: auto;", tableOutput("modal_solution_table"))
                          ),
                          card_footer(textOutput("modal_iter_desc")))),
      easyClose = TRUE, footer = modalButton("close")
    ))
  })
  
  # output renderers for the modal dialog =========================================================
  
  # renders the title inside the modal card
  output$modal_iter_title <- renderText({
    req(input$selected_iter_idx)
    selected_index = as.numeric(input$selected_iter_idx)
    if(selected_index == 1) {
      "Initial Tableau (start)" 
    } else if (selected_index == length(solution_data$result$iterations)){
      paste0("Final Optimal Tableau (Iteration ", selected_index - 1, ")")
      
    }else{
      paste("Iteration ", selected_index - 1)
    }
  })
  
  #renders the main tableau for the selected iteration
  output$modal_iter_table <- renderTable({
    req(input$selected_iter_idx)
    solution_data$result$iterations[[as.numeric(input$selected_iter_idx)]]
  }, rownames = TRUE, digits = 2)
  
  # renders the basic solution for the selected iteration
  output$modal_solution_table <- renderTable({
    req(input$selected_iter_idx, solution_data$result$iterSolutions)
    solution_data$result$iterSolutions[[as.numeric(input$selected_iter_idx)]]
  }, rownames = FALSE, digits = 4)
  
  # renders a descriptive footer text inside the modal card
  output$modal_iter_desc <- renderText({
    req(input$selected_iter_idx)
    if(as.numeric(input$selected_iter_idx) == length(solution_data$result$iterations)){
      "algorithm terminated: all coefficients in objective row are non-negative." 
    } else {
      "algorithm in progress..."
    }
  })
  
  
  # static data renderers for problem statement tab ============================================================
  
  #renders the pollutant targets table
  output$targets_table <- renderTable({
    data.frame(
      pollutant = c("co2", "nox", "so2", "pm2.5", "ch4", "voc", "co", "nh3", "black carbon", "n2o"),
      `target minimum (tons)` = c(1000, 35, 25, 20, 60, 45, 80, 12, 6, 10),
      check.names = FALSE
    )
  }, rownames = FALSE)
  
  #renders the project reference table
  output$project_ref_table <- renderTable({
    # convert the projects_matrix into a data.frame
    projects_df <- as.data.frame(projects_matrix)
    
    # add the project names as the first column
    projects_df <- cbind(`Mitigation Project` = rownames(projects_df), projects_df)
    
    
    #rename the Costs column 
    colnames(projects_df)[1] <- "Mitigation Project"
    colnames(projects_df)[2] <- "Cost ($)"
    
    # return the final data frame to be displayed
    projects_df
    
  }, rownames = FALSE, digits = 4)
}