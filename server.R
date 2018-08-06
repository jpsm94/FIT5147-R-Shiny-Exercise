# server.R


library(shiny)
library(ggplot2)
library(rgdal)
library(rgeos)
library(plyr)
library(gpclib)
library(maptools)
#gpclibPermit()


# population scale
pop.scale <- 1000

# Read data
df <- read.csv(file="data/task2data.csv",
               head=TRUE, fileEncoding='UTF-8-BOM')

# only totals
total.pop.data <- subset(df, df$region=='TOTAL AUSTRALIA')


# Read shape files
aus = readOGR(dsn="data", layer="AUS_adm1")
aus@data$id = rownames(aus@data)

aus.buf = gBuffer(aus, width=0, byid=TRUE)
aus.points = fortify(aus.buf, region="id")
aus.df = join(aus.points, aus@data, by="id")

# rename State/Territory column
names(aus.df)[names(aus.df) == 'NAME_1'] <- 'region'

# prepare data for map
df2 <- df
df2 <- subset(df2, df2$region!='TOTAL AUSTRALIA') # exclude totals
df2$km2 <- NULL # km2 not needed anymore, density already stored in another column

# merge shape and data on 'region'
map.df <- merge(x=aus.df, y=df2, by=c('region'))



shinyServer(function(input, output) {

  region.pop.data <- reactive({
    subset(df, df$region==input$region) # update data upon selection of region
  })

  # population trend bar chart for selected region and Australia as a whole
  output$trend <- renderPlot({
    ggplot() +
      geom_bar(data=total.pop.data, aes(x=year+0.1, y=pop/pop.scale, fill='Australia'), width=0.7, color="white", stat="identity") +
      #geom_smooth(data=total.pop.data, aes(x=year+0.1, y=pop/pop.scale), method="loess", size=1.2) +
      
      geom_bar(data=region.pop.data(), aes(x=year-0.1, y=pop/pop.scale, fill=region), width=0.7, color="white", stat="identity") +
      #geom_smooth(data=region.pop.data(), aes(x=year-0.1, y=pop/pop.scale), method="loess", size=1.2) +
      
      labs(x="Year", y="Population (in thousands)") +
      ggtitle(paste('Population in', input$region, 'vs entire Australia')) +
      theme(plot.title=element_text(hjust=0.5, face="bold", size=20)) +
      
      scale_x_discrete(limits=c(2005:2015)) +
      scale_fill_manual(name="", values=c("#006633", "#FFF000"), 
                        guide=guide_legend(direction="horizontal", title.position="top",
                                           label.position="bottom", label.hjust=0.5, label.vjust=0.5, 
                                           label.theme=element_text(angle=90)))
  })
  
  year.data <- reactive({
    # update data upon selection of year
    yr.df <- subset(map.df, map.df$year==input$year)
    if (input$exclude.act) { # update data upon selection of 'exclude ACT' option
      yr.df <- subset(yr.df, yr.df$region!='Australian Capital Territory')
    }
    yr.df
  })
  
  # choropleth chart
  output$choropleth <- renderPlot({
    plot <- ggplot(data=year.data()) +
      geom_polygon() +
      geom_path(color="white") +
      coord_equal(xlim=c(110,155), ylim=c(-45,-10)) # include limits to center AUS map
    
    if (input$view.option=='Population') {
      plot + 
        aes(long, lat, group=group, fill=(pop/pop.scale)) +
        scale_fill_gradient(low="#99CCFF", high="#000666", guide="colorbar") +
        labs(x="", y="", fill='population\n(in thousands)') +
        ggtitle(paste('Population in', input$year)) + 
        theme(plot.title=element_text(hjust=0.5, color="#000666", face="bold", size=22))
    } else {
      plot + 
        aes(long, lat, group=group, fill=density) +
        scale_fill_gradient(low="#FF9999", high="#990033", guide="colorbar") + 
        labs(x="", y="", fill='# people\nper sq km') +
        ggtitle(paste('Population Density in', input$year)) + 
        theme(plot.title=element_text(hjust=0.5, color="#990033", face="bold", size=22))
    }
  })
  
})

