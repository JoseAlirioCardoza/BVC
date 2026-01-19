library(chromote)
library(rvest)
library(dplyr)
library(stringr)
library(readr)

# Configuración de Chromote para GitHub Actions
Sys.setenv(CHROMOTE_CHROME = "/usr/bin/google-chrome")

# 1. Iniciar sesión
b <- ChromoteSession$new()
b$Page$navigate("https://www.bolsadecaracas.com/resumen-mercado/")

# 2. Espera generosa para asegurar carga en el servidor
Sys.sleep(15) 

# 3. Capturar HTML
html_renderizado <- b$Runtime$evaluate("document.querySelector('body').innerHTML")$result$value
pagina <- read_html(html_renderizado)

# 4. Procesar tabla con la lógica que funcionó en tu PC
tabla_bvc <- pagina %>% html_element("#tbl-resumen-mercado") %>% html_table()

if (!is.null(tabla_bvc)) {
  acciones_final <- tabla_bvc %>%
    as_tibble(.name_repair = "minimal") %>% 
    setNames(paste0("Col", 1:ncol(.))) %>%
    select(Nombre = Col2, Simbolo = Col3, Precio_Bs = Col4, Variacion = Col6) %>%
    filter(str_detect(Simbolo, "^[A-Z]")) %>%
    filter(!is.na(Precio_Bs))
  
  # 5. Guardar el CSV que leerá tu App
  write_csv(acciones_final, "data_bvc_actual.csv")
  print("Datos actualizados exitosamente.")
}

b$parent$close()