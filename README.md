# City Pollution Reduction Plan Optimizer

![Language](https://img.shields.io/badge/Language-R-blue.svg)
![Framework](https://img.shields.io/badge/Framework-Shiny-hotpink.svg)

An interactive web application built with R and Shiny that uses the Simplex Algorithm to determine the most cost-effective combination of environmental projects to meet specific pollution reduction targets.

## Overview

The City of Greenvale is mandated to reduce its pollution footprint by meeting specific annual reduction targets for ten priority pollutants (CO2, NOx, SO2, etc.). The city has a list of 30 available mitigation projects, each with an associated cost and a specific impact on reducing each pollutant.

This application serves as a decision-support tool for city planners. It solves this complex resource allocation problem by framing it as a Linear Programming problem and finding the optimal solution that **minimizes total cost** while satisfying all environmental constraints.

## Features

-   **Interactive Project Selection:** Users can dynamically select which of the 30 available mitigation projects to include in the optimization problem.
-   **Real-time Tableau:** The initial Simplex tableau is displayed and updates live as projects are selected, providing immediate mathematical insight.
-   **One-Click Optimization:** A single button runs a custom-built Simplex Algorithm to find the optimal solution.
-   **Comprehensive Results Dashboard:** After optimization, the app displays:
    -   The total minimum cost (Z-value).
    -   A summary of which projects to fund and by how many units.
    -   A summary of the total pollutant reduction achieved, compared against targets.
    -   The final mathematical basic solution for all variables.
-   **Data Visualization:** A horizontal bar chart visualizes the recommended project allocation, making it easy to interpret the results.
-   **Step-by-Step Algorithm Viewer:** An interactive modal allows users to inspect the full tableau and basic solution at every single iteration of the Simplex algorithm.
-   **Robust Error Handling:** The app gracefully handles infeasible solutions, informing the user when the selected projects cannot meet the required targets.
-   **Modern UI:** Built with `bslib` for a clean, modern look, including a dark/light mode toggle.

## Technical Formulation

The application solves a classic Linear Programming problem.

-   **Objective Function (Minimize Cost):**
    ```math
    \text{Minimize } Z = \sum_{i=1}^{n} (\text{cost}_i \cdot x_i)
    ```
    Where *x<sub>i</sub>* is the number of units of project *i* and *cost<sub>i</sub>* is its cost per unit.

-   **Constraints:**
    1.  **Pollution Reduction:** For each pollutant *j*, the total reduction must meet or exceed the target.
        ```math
        \sum_{i=1}^{n} (\text{pollutant}_{ji} \cdot x_i) \ge \text{minPollutant}_j, \quad \text{for } j=1..10
        ```
    2.  **Project Limits:** The number of units for each project is non-negative and capped at a maximum of 20.
        ```math
        0 \le x_i \le 20, \quad \text{for } i=1..n
        ```

The application solves this by setting up and solving the **dual problem** using a custom implementation of the Simplex Algorithm.

## How to Use the Application

### Option A: Use the Web Application (Recommended)

This is the simplest way to use the optimizer. No installation is needed.

1.  **Open the Link:** Click the link below to open the application directly in your web browser.
    > **Link:** **(https://rannssuuu.shinyapps.io/finalproject/)**
2.  **Start Using:** The application is ready to use.

### Option B: Run the Application Locally (Advanced)

This option is for users who have R/RStudio installed and want to run the code on their own machine.

1.  **Prerequisites:** Ensure you have [R](https://cran.r-project.org/) and [RStudio](https://posit.co/download/rstudio-desktop/) installed.

2.  **Download Project:** Download and unzip the project folder to your computer.

3.  **Open Project:** In RStudio, go to `File > Open Project...` and open the `.Rproj` file from the downloaded folder.

4.  **Install Packages:** In the RStudio Console, run the following command to install the necessary packages:
    ```r
    install.packages(c("shiny", "bslib", "shinyWidgets", "ggplot2", "thematic", "scales"))
    ```

5.  **Run App:** Open either the `ui.R` or `server.R` file and click the "Run App" button at the top of the editor.

## Technologies Used

-   **R:** The core programming language for all calculations.
-   **Shiny:** The web framework for building the interactive user interface.
-   **bslib:** For modern Bootstrap 5 styling, theming, and UI components like `card()` and `page_sidebar()`.
-   **shinyWidgets:** For the dark/light mode toggle.
-   **ggplot2:** For creating the data visualization plot.
-   **thematic:** For automatically styling `ggplot2` plots to match the Shiny theme.
-   **scales:** For formatting numbers into currency for display.

## Project Structure

The application logic is modularized into several R scripts:

-   `ui.R`: Defines the structure, layout, and appearance of the user interface.
-   `server.R`: Contains the "brain" of the app. It handles user inputs, calls the solver function, and renders all the dynamic outputs (tables, plots, UI cards).
-   `setup.R`: The data and setup layer. It defines all project data (`projects_matrix`), pollutant targets, and contains the functions (`BuildInitialMatrix`, `SetUpTableu`) to construct the initial problem.
-   `simplex.R`: The core algorithmic engine. It contains the custom implementation of the `Simplex` algorithm, `GaussJordanSimplex`, and helper functions for pivot selection.
-   `solution.R`: The controller layer. It contains the main `Solution()` function that orchestrates the entire process: it calls `setup.R` functions to build the problem, calls `simplex.R` to solve it, and then calls formatter functions (`getProjects`, `getPollutantSummary`) to prepare the results for the server.

## Author

-   **Lance Joseph F. Perus**
    -   Developed as a Final Project for CMSC 150: Numerical and Symbolic Computation.
