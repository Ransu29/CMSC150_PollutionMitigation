library(shiny)          # ui lib
library(bslib)          # bootstrap ui lib
library(shinyWidgets)   # for extra ui elements 



# made for the navbar not turning darkmode
# looks good in dark mode, as default styles might not be perfect
customCssForDarkMode <- tags$head(
  tags$style(HTML("
    /* style for the navbar background in dark mode */
    [data-bs-theme='dark'] .navbar {
        background-color: #212529 ;
        border-bottom: 1px solid #444;
    }
    
    /* style for the main app title in the navbar (dark mode) */
    [data-bs-theme='dark'] .navbar-brand {
        color: #ffffff ;
    }
    
    /* style for the navigation links (e.g., 'optimizer') in dark mode */
    [data-bs-theme='dark'] .navbar-nav .nav-link {
        color: #cccccc;
    }
  "))
)


# ui ===================================================================================

# NavbarPage - main application layout with a navigation bar at the top
navbarPage(
  title = "City Pollution Reduction Plan",
  header = customCssForDarkMode, # applies the custom css 
  
  # set the global visual theme using bslib
  theme = bs_theme(
    version = 5, 
    bootswatch = "materia", # the theme
    primary = "#2080e3"      # custom primary color for buttons and highlights
  ),
  
  # navigation bar items =====================================================================
  
  nav_spacer(), # adds flexible space to push the next item to the right
  nav_item(
    # adds a dark/light mode toggle switch to the navbar from the shinywidgets package.
    input_dark_mode(id = "theme_mode", mode = "light")
  ),
  
  
  # Optimizer tab
  # main tab where the user performs the optimization
  tabPanel(
    "Optimizer",
    # PageSidebar creates layout with a main content area and sidebar
    page_sidebar(
      
      # content of the sidebar panel
      sidebar = sidebar(
        title = "Mitigation projects",
        p("Select projects to include in the optimization problem."),
        
        # container for the 'select all' and 'clear all' buttons
        div(style="display: flex; justify-content: space-between; margin-bottom: 10px;",
            actionButton("choose_all", "select all", icon = icon("check-square"), class = "btn-success"),
            actionButton("clear_all", "clear all", icon = icon("square-xmark"), class = "btn-warning")
        ),
        
        # main checkbox group for project selection
        # populated dynamically from the server
        checkboxGroupInput(
          "chosen_projects",
          "available projects:",
          choices = NULL, 
          selected = NULL
        ),
        width = 400
      ),
      
      # main content area of the page
      card(
        card_header(
          "Optimization Control",
          # the primary button that triggers the simplex algorithm calculation.
          actionButton("run_simplex", "Optimize Cost", icon = icon("cogs"), class = "btn-primary"),
          style = "display:flex; align-items: center; justify-content: space-between;"
        ),
        card_body(
          #  initial simplex tableau
          card(
            card_header("Initial Problem Setup (tableau)"),
            card_body(
              # tableOutput links to an output object in the server
              div(style = "overflow-x: auto;",
                  tableOutput("live_initial_tableau")
              )
            )
          ),
          # placeholder, build and insert the results ui here
          # after the user clicks the "optimize cost" button
          uiOutput("results_ui")
        )
      )
    )
  ),
  
  
  # problem statement tab ==================================================================================
  tabPanel(
    "Problem Statement",
    fluidPage(
      style = "padding-top: 20px;",
      
      # main header for the page
      div(class = "text-center mb-4",
          h1("City Pollution Reduction Plan"),
          h4("CMSC 150: Numerical and Symbolic Computation | Final Project"),
          p("1st semester 2025-2026")
      ),
      
      #  responsive grid
      layout_columns(
        col_widths = c(6, 6),
        
        # problem card
        card(
          height = "100%", # ensures cards in the same row have equal height
          card_header(h4("The Greenvale Mandate")),
          card_body(
            p("The City of Greenvale has been mandated by the national government to drastically reduce its pollution footprint within the next year."),
            p("The environmental commission has identified ", strong("ten priority pollutants"), " (co2, nox, so2, etc.) that must meet specific annual reduction targets."),
            hr(),
            h5("The Algorithm"),
            p("To solve this complex resource allocation problem, this application utilizes the ", strong("simplex algorithm"), "."),
            p("The simplex algorithm is an iterative method for linear programming used to find the optimal solution (minimum cost) within a feasible region defined by the environmental constraints.")
          )
        ),
        
        # formula card
        card(
          height = "100%",
          card_header(h4("Mathematical Formulation")),
          card_body(
            p("We define the linear programming problem as follows:"),
            strong("Objective function (minimize cost):"),
            # withMathJax enables latex-style math rendering
            withMathJax(helpText("$$ \\text{minimize } z = \\sum_{i=1}^{n} (cost_i \\cdot x_i) $$")),
            strong("Subject to constraints:"),
            p("1. Pollution reduction requirement:"),
            withMathJax(helpText("$$ \\sum_{i=1}^{n} (pollutant_{ji} \\cdot x_i) \\ge minpollutant_j, \\quad \\text{for } j=1..m $$")),
            p("2. Project constraints (min/max limits per project):"),
            withMathJax(helpText("$$ 0 \\le x_i \\le 20, \\quad \\text{for } i=1..n $$"))
          )
        )
      ),
      br(),
      # reference tables
      layout_columns(
        col_widths = c(4, 8),
        card(
          card_header(h5("Pollutant Reduction Targets")),
          card_body(
            # the div wrapper creates a scrollable area if the table is too tall
            div(style = "height: 500px; overflow-y: auto;", tableOutput("targets_table"))
          )
        ),
        card(
          card_header(h5("Available Mitigation Options (costs)")),
          card_body(
            p("There are 30 options available. Each unit represents a standard package."),
            div(style = "height: 500px; overflow-y: auto;", tableOutput("project_ref_table"))
          )
        )
      )
    )
  ),
  
  
  # about tab =========================================================================
  # contains data about the project, author, and user instructions
  tabPanel(
    "About",
    fluidPage(
      style = "padding-top: 20px;",
      
      # card for author details
      card(
        class = "mb-4",
        card_header(h3("Project Details")),
        card_body(
          layout_columns(
            col_widths = c(11, 11),
            div(
              class = "text-center", 
              img(src = "author.jpg", height = "150px", width = "150px",
                  class = "rounded-circle mb-3 border", style = "object-fit: cover;"), 
              h4( "Author"),
              h5(strong("Lance Joseph F. Perus")),
              p("Sophomore student | University of the Philippines"),
              p(class = "text-muted", "Developed as a final project requirement.")
            )
            # div(
            #   class = "text-center",
            #   img(src = "instructor.jpg", height = "150px", width = "150px", class = "rounded-circle mb-3 border", style = "object-fit: cover;"),
            #   h4("laboratory instructor"),
            #   h5(strong("mr. jamlech iram gojo cruz")),
            #   p("cmsc 150: numerical and symbolic computation"),
            #   p("1st semester, a.y. 2025-2026")
            #   
            # )
          )
        )
      ),
      
      # educational context and interesting facts
      layout_columns(
        col_widths = c(6, 6),
        card(
          height = "100%",
          card_header(h4(icon("book-open"), " About CMSC 150")),
          card_body(
            p(strong("Numerical and Symbolic Computation"), " is a pivotal course in computer science that
              bridges the gap between pure mathematics and computational algorithms."),
            p("The course explores how computers solve mathematical problems that 
              are often too complex or tedious for manual calculation. topics include 
              finding roots of non-linear equations, numerical integration, and optimization techniques
              like the simplex method used in this app."),
            p("This project serves as a practical demonstration of how these abstract 
              numerical methods are applied to solve real-world resource allocation problems.")
          )
        ),
        card(
          height = "100%",
          card_header(h4(icon("lightbulb"), " Interesting Facts")),
          card_body(
            tags$ul(
              tags$ul(
                tags$li(strong("Top 10 Algorithm:"), " The simplex algorithm, developed by george dantzig in 1947, is frequently cited as one of the top 10 most important algorithms of the 20th century."),
                tags$li(strong("Accidentally Lucky:"), " George Dantzig famously solved two 'unsolved' statistics problems because he arrived late to class and thought they were homework."),
                tags$li(strong("High Dimensionality:"), " While humans can visualize 2 or 3 dimensions, real linear programs often involve hundreds or thousands of dimensions—far beyond human intuition."),
                tags$li(strong("Powering the real world:"), " Linear programming decides airline schedules, delivery routes, energy production, crop planning, and even which ingredients go into animal feed."),
                tags$li(strong("LP runs the internet:"), " Data centers use linear programming to allocate cpu, memory, and bandwidth to millions of users while minimizing energy consumption."),
              )
            )
          )
        )
      ),
      
      br(),
      
      # layout for technical stack and user manual.
      layout_columns(
        col_widths = c(5, 7),
        card(
          card_header(h4("Technologies used")),
          card_body(
            tags$ul(
              tags$li(strong("R language:"), " core logic and numerical calculation."),
              tags$li(strong("shiny:"), " interactive web framework."),
              tags$li(strong("bslib:"), " bootstrap 5 styling and dark mode support."),
              tags$li(strong("ggplot2 & thematic:"), " data visualization adapted for dark/light themes."),
              tags$li(strong("Simplex Algorithm:"), " The author's custom implementation of the maximization/minimization logic.")
            )
          )
        ),
        card(
          card_header(h4("User Manual")),
          card_body(
            #  collapsible, expandable set of instructions
            accordion(
              accordion_panel(
                "How to use this application",
                tags$ol(
                  tags$li(strong("Navigate to the Optimizer Tab:"), " This is the main workspace."),
                  tags$li(strong("Select mitigation projects:"), " In the sidebar, check the boxes for the projects you want the city to consider."),
                  tags$li(strong("Run optimization:"), " Click the blue 'optimize cost' button."),
                  tags$li(strong("Analyze results:"), " The optimal mix and cost will appear, along with a visualization."),
                  tags$li(strong("View iterations:"), " Click 'view steps' to see mathematical tableaus.")
                )
              ),
              accordion_panel(
                "Understanding the output",
                p("The", strong("optimal project mix"), " table tells you how many units of each project to buy."),
                p("If you see an", strong("infeasible solution"), " warning, the selected projects cannot meet the targets.")
              )
            )
          )
        )
      )
    )
  )
)