# ui.R

appCSS <- "
  .plot-container {
    position: relative;
  }
  .loading-spinner {
    position: absolute;
    left: 50%;
    top: 50%;
    z-index: -1;
    margin-top: -128px;  /* half of the spinner's height */
    margin-left: -128px; /* half of the spinner's width */
  }"

shinyUI(
  fluidPage(
    # CSS for "loading" spinner
    tags$head(tags$style(HTML(appCSS))),

    titlePanel("Population Trend"),
    
    # Row for Population Trend Plot
    fluidRow(
      column(3, 
             wellPanel(
               radioButtons("region", label="Select State or Territory",
                            choices=c('New South Wales', 'Victoria', 'Queensland', 'South Australia', 'Western Australia',
                                      'Tasmania', 'Northern Territory', 'Australian Capital Territory'), 
                            selected='New South Wales'))
      ),
      
      column(9,
            div(class="plot-container",
                tags$img(src="spinner.gif", class="loading-spinner"),
                plotOutput("trend", hover=hoverOpts(id="hoverTrendPlot", delay=0))
            )
      )
    ),
    
    titlePanel("Choropleth Chart"),
    
    # Row for Choropleth
    fluidRow(
      column(3,
             wellPanel(
               selectInput("year", label="Select Year", 
                           choices=c(2005:2015), 
                           selected=2015),
               radioButtons("view.option", label= "View Option",
                            choices=list('Population', 'Density'), selected='Population'),
               
               div("ACT Option", style="font-weight:bold"),
               checkboxInput("exclude.act", label=("Exclude ACT"), value=FALSE))
      ),
      
      column(9,
             div(class="plot-container",
                tags$img(src="spinner.gif", class="loading-spinner"),
                plotOutput("choropleth", hover=hoverOpts(id="hoverChoroPlot", delay=0))
             )
      )
    )
))