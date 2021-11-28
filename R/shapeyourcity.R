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
    
    r$status_code
    
    c<-httr::content(r)
    
    
    parse_project_data <- function(data){
      tibble(id=data$id,type=data$type,url=data$links$self) %>%
        bind_cols(data$attributes[unlist(data$attributes %>% lapply(length))==1] %>% as_tibble())
    }
    
    result <- bind_rows(result,c$data %>% lapply(parse_project_data)) %>% bind_rows()
    url <- c$links[["next"]]
  }
  result
}
