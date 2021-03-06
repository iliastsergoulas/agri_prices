# This R script is created as a Shiny application to use raw agricultural commodities data, 
# available by Quandl, and create plots and statistics.
# The code is available under MIT license, as stipulated in https://github.com/iliastsergoulas/agri_prices/blob/master/LICENSE.
# Author: Ilias Tsergoulas, Website: www.agristats.eu

library(shiny)
library(shinythemes)
library(shinydashboard)
library(corrplot)
library(Quandl)
library(forecast)
library(dygraphs)
library(lubridate)

printMoney <- function(x){ # A function to show number as currency
    format(x, digits=10, nsmall=2, decimal.mark=",", big.mark=".")
}
percent <- function(x, digits = 2, format = "f", ...) { # A function to show number as percentage
    paste0(formatC(100 * x, format = format, digits = digits, ...), "%")
}
specify_decimal <- function(x, k) format(round(x, k), nsmall=k) # A function to show number with k decimal places

Quandl.api_key("KCo4sXzWEzSAb81ff3VP") # Setting API key to have unlimited access to databases
data_codes<-c("COM/WLD_SUGAR_EU", "COM/WLD_SUGAR_WLD", "COM/WLD_SUGAR_US", # Setting wanted Quandl database codes
              "COM/COFFEE_BRZL", "COM/COFFEE_CLMB", "COM/WLD_COFFEE_ARABIC",
              "COM/WLD_RICE_05", "COM/WLD_RICE_25", "COM/WLD_RICE_05_VNM",
              "COM/BEEF_S", "COM/BEEF_C", "COM/WLD_BEEF",
              "COM/WLD_BANANA_EU", "COM/WLD_BANANA_US", "COM/PBANSOP_USD",
              "COM/WLD_COCOA", "COM/WLD_COTTON_A_INDX", "COM/OATS", "COM/MILK",
              "COM/EGGS", "COM/BUTTER", "COM/WLD_TOBAC_US","COM/WLD_ORANGE",
              "COM/WLD_WHEAT_CANADI", "COM/WLD_WHEAT_US_HRW", "COM/WLD_WHEAT_US_SRW", "COM/PWHEAMT_USD",
              "COM/WOOL", "COM/WOOL_60_62", "COM/WOOL_60", "COM/WOOL_58", "COM/WOOL_62",
              "COM/CORN_MEAL", "COM/CORN_FEED", "COM/WLD_MAIZE", "COM/PMAIZMT_USD",
              "COM/WLD_LAMB", "COM/WLD_CHICKEN", "COM/PSHRI_USD", "COM/WLD_SHRIMP_MEX",
              "COM/WLD_SUNFLOWER_OIL", "COM/WLD_GRNUT_OIL", "COM/WLD_COCONUT_OIL", "COM/WLD_RAPESEED_OIL", 
              "COM/WLD_PALM_OIL", "COM/WLD_SOYBEAN_OIL", "COM/POLVOIL_USD",
              "COM/WLD_TEA_KOLKATA", "COM/WLD_TEA_MOMBASA", "COM/WLD_TEA_COLOMBO", "COM/WLD_TEA_AVG",
              "COM/WLD_IBEVERAGES", "COM/WLD_IGRAINS", "COM/WLD_IFOOD", "COM/WLD_IFERTILIZERS", "COM/WLD_IAGRICULTURE", "COM/WLD_IENERGY") 
# Setting Quandl codes respective description
data_descr<-c("Sugar Price, EU, cents/kg", "Sugar Price, world, cents/kg", "Sugar Price, US, cents/kg", 
              "Coffee, Brazilian, Comp.", "Coffee, Colombian, NY lb.", "Coffee Price, Arabica, cents/kg",
              "Rice, Thai 5% ,($/mt)", "Rice, Thai 25% ,($/mt)", "Rice, Viet Namese 5%,($/mt)",
              "Beef - Select 1", "Beef - Choice 1", "Beef,($/kg)",
              "Banana, Europe,($/kg)", "Banana, US,($/kg)", "Bananas, Central American and Ecuador, FOB U.S. Ports, US$ per metric ton",
              "Cocoa,($/kg)","Cotton, A Index,($/kg)", "Oats, No. 2 milling, Mnpls; $ per bu", "Milk, Nonfat dry, Chicago",
              "Eggs, large white, Chicago dozen", "Butter, AA Chicago, lb","Tobacco, US import u.v.,($/mt)",
              "Orange,($/kg)", 
              "Wheat, Canadian,($/mt)", "Wheat, US HRW,($/mt)", "Wheat, US SRW,($/mt)", "Wheat, No.1 Hard Red Winter ($/mt)",
              "Wool, 64s", "Wool, 60-62s", "Wool, 60s", "Wool, 58s", "Wool, 62s",
              "Corn gluten meal, Midwest, ton", "Corn gluten feed, Midwest, ton", "Maize,($/mt)", "Maize (corn), U.S. No.2 Yellow, FOB Gulf of Mexico, U.S. price, US$ per metric ton",
              "Meat, sheep,($/kg)", "Meat, chicken,($/kg)", "Shrimp, shell-on headless, 26-30 count/pound, Mexican origin, $/kg", "Shirmps, Mexican,($/kg)",
              "Sunflower oil,($/mt)", "Groundnut oil,($/mt)", "Coconut oil,($/mt)", "Rapeseed oil,($/mt)", "Palm oil,($/mt)",
              "Soybean oil,($/mt)", "Olive Oil, extra virgin less than 1% free fatty acid,($/mt)",
              "Tea, Kolkata,($/kg)", "Tea, Mombasa,($/kg)", "Tea, Colombo,($/kg)", "Tea, avg 3 auctions,($/kg)",
              "Beverages Index", "Grains Index", "Food Index", "Fertilizers Index", "Agriculture Index", "Energy Index")
data_product<-c("Sugar","Sugar","Sugar", 
                "Coffee","Coffee","Coffee", 
                "Rice","Rice","Rice",
                "Beef", "Beef", "Beef",
                "Bananas", "Bananas", "Bananas",
                "Cocoa", "Cotton", "Oats","Milk",
                "Eggs", "Butter", "Tobacco", "Oranges",
                "Wheat", "Wheat", "Wheat", "Wheat",
                "Wool", "Wool", "Wool", "Wool", "Wool",
                "Corn", "Corn", "Corn", "Corn",
                "Meat", "Meat", "Shrimps", "Shrimps",
                "Oils", "Oils", "Oils", "Oils", "Oils", "Oils", "Oils",
                "Tea", "Tea", "Tea", "Tea",
                "Indexes", "Indexes", "Indexes", "Indexes", "Indexes", "Indexes")
data_quandl<-data.frame(data_descr, data_codes, data_product) # Binding codes and description to dataframe

header <- dashboardHeader(title = "Agricultural commodities prices ", titleWidth=600) # Header of dashboard
sidebar <- dashboardSidebar(sidebarMenu(
    selectInput('commodity', 'Product', choices = unique(data_quandl$data_product)),
    selectInput('period', 'Prediction period (months)', 
                choices = c("6", "12", "18", "24", "30", "36"), selected='12')),
    tags$footer(tags$p("This application is based on Quandl data. Simply choose the 
                       product/commodity you wish to examine and the period 
                       (number of months) you want to project a forecast on. The top plot 
                       is of all products while the ones below are for each product alone.")))
frow1 <- fluidRow( # Creating row
    title = "Total",
    status="success",
    collapsible = TRUE, 
    mainPanel(dygraphOutput("view"), width='98%')
)
frow2 <- fluidRow( # Creating row
    status="success",
    collapsible = TRUE, 
    mainPanel(uiOutput("plots"), width='98%')
)

body <- dashboardBody(frow1, frow2) # Binding rows to body of dashboard
ui <- dashboardPage(header, sidebar, body, skin="yellow") # Binding elements of dashboard

server <- function(input, output) {
    mydata <- reactive({ # Adding reactive data information
        data_filtered<-as.data.frame(data_quandl[which(data_quandl$data_product==input$commodity),])
        mydata<-data.frame(Date= character(0), Value= character(0), Description=character(0))
        for (i in 1:nrow(data_filtered)){ # Getting prices data based on Quandl code
            temp<-Quandl(as.character(data_filtered[i,2]), collapse = "monthly")
            temp$Description<-as.character(data_filtered[i,1])
            colnames(temp)<-c("Date", "Value", "Description")
            mydata<-rbind(mydata, temp)
        }
        mydata
    })
    mydata_multiple<- reactive({ # Reshaping mydata dataframe for multiple view
        unique_descriptions<-unique(mydata()$Description)
        mydata_multiple<-reshape(mydata(), direction = "wide", idvar = "Date", timevar = "Description")
        #colnames(mydata_multiple)<-c("Date", unique_descriptions[1], unique_descriptions[2], unique_descriptions[3])
        mydata_multiple<-xts(mydata_multiple, order.by=as.POSIXct(mydata_multiple$Date))
        mydata_multiple<-mydata_multiple[,-c(1)]
    })
    output$view <- renderDygraph({ # Creating chart
        #combined <- cbind(mydata_multiple(), actual=mydata_multiple())
        dygraph(mydata_multiple(), main="Commodities prices", group = "commodities")%>%
            dyAxis("y", label = "Commodity price")%>%
            dyRangeSelector(height = 20)
    })
    mylength<-reactive({ # Getting number of datasets
        mylength<-length(unique(mydata()$Description))
    })
    output$plots <- renderUI({ # Calling createplots() function and plotting dygraphs
        createPlots()
        plot_output_list <- lapply(1:mylength(), function(i) {
            plotname <- paste("plot", i, sep="")
            dygraphOutput(plotname)
        })
        do.call(tagList, plot_output_list) # Converting the list to a tagList.
    })
    createPlots <- reactive ({ # Creating dygraph plots for as many datasets are available
        # Calling renderPlot for each one.
        last_date<-mydata()
        for (i in 1:mylength()) {
            # With local each item gets its own number.
            local({
                my_i <- i
                plotname=paste("plot", my_i, sep="") # Setting flexible names
                mydata_product <- unique(mydata()$Description)[my_i] # Getting unique descriptions
                mydata_ts<-mydata()[which(mydata()$Description==mydata_product),]
                mydata_ts<-xts(mydata_ts, order.by=as.POSIXct(mydata_ts$Date))
                mydata_predicted <- forecast(as.numeric(mydata_ts$Value), h=as.numeric(input$period)) # Creating forecast
                mydata_predicted <- data.frame(Date = seq(mdy('11/30/2017'), by = 'months', length.out = as.numeric(input$period)),
                                               Forecast = mydata_predicted$mean,Hi_95 = mydata_predicted$upper[,2],
                                               Lo_95 = mydata_predicted$lower[,2])
                mydata_xts <- xts(mydata_predicted, order.by = as.POSIXct(mydata_predicted$Date))
                mydata_predicted <- merge(mydata_ts, mydata_xts) # Merging xts object with forecast
                mydata_predicted <- mydata_predicted[,c("Value", "Forecast", "Hi_95", "Lo_95")]
                output[[plotname]] <- renderDygraph({ # Rendering dygraphs
                    dygraph(mydata_predicted, main=mydata_ts[1,3], group = "commodities")%>%
                        dyAxis("y", label = "Commodity price")%>%
                        dyRangeSelector(height = 20)
                })
            })
        }
    })
}
shinyApp(ui, server)