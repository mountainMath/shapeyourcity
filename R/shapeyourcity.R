library(dplyr)

get_all_projects <- function(){
  get_token <- function(url="https://shapeyourcity.ca/embeds/projectfinder"){
    r<-rvest::read_html("https://shapeyourcity.ca/embeds/projectfinder")
    
    s <- r %>%
      rvest::html_element('script#__NEXT_DATA__') %>%
      rvest::html_text() %>%
      jsonlite::fromJSON()
    
    token <- s$props$pageProps$initialState$anonymousUser$token
  }
  
  token <- get_token()
  
  
  
  url <- "https://shapeyourcity.ca/api/v2/projects?page=1&per_page=100"
  
  result <- NULL
  
  while (!is.null(url)) {
    
    r<-httr::GET(url,httr::add_headers(Authorization=paste0("Bearer ",token)))
    
    #r$status_code
    
    c<-httr::content(r)
    
    
    parse_project_data_old <- function(data){
      
      tibble(id=data$id,type=data$type,url=data$links$self) %>%
        bind_cols(data$attributes[unlist(data$attributes %>% lapply(length))==1] %>% as_tibble())
    }
    
    parse_project_data <- function(data){
      attributes <- data$attributes[unlist(data$attributes %>% lapply(length))>=1] %>% 
        as_tibble() %>%
        summarise_all(function(d) unique(d) %>% paste0(.,collapse = ", "))
      tibble(id=data$id,type=data$type,url=data$links$self) %>%
        bind_cols(attributes)
    }
    
    result <- bind_rows(result,c$data %>% lapply(parse_project_data)) %>% bind_rows()
    url <- c$links[["next"]]
  }
  result
}


get_key_dates_for_page <- function(url){
  r<-rvest::read_html(url)
  
  data <- r %>% 
    rvest::html_nodes("div.widget_key_date ul li") %>%
    lapply(function(n){
      title_string <- n %>% 
        rvest::html_node(".key-date-title") %>% 
        rvest::html_text() %>%
        trimws() %>% 
        unlist()
      date_string <- n %>% 
        rvest::html_node(".key-date-date") %>% 
        rvest::html_text() %>%
        trimws() %>% 
        unlist()
      tibble(title=title_string,date_string=date_string)
    }) |>
    bind_rows() |>
    mutate(url=url)
}

get_key_dates_for_pages <- function(urls){
  urls %>% lapply(get_key_dates_for_page)
}


get_key_dates_for_all_results <- function(results){
  get_key_dates_for_pages(results$url) %>%
    bind_rows() %>%
    left_join(results %>% select(id,url),by="url")
}

