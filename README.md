# ScrApi

Scrapi is a Vapor-based microservice that fetches and parses HTML URL and returns parsed JSON data accordingly to parameters passed.

## Usage - JSON list

Call `POST /getList` endpoint to get a JSON list.

Pass configuration JSON in POST body.
Configuration JSON consists of 3 parts:
1. `url` - URL to be called and parsed
1. `listSelector` - CSS selector that matches list elements. Usually that is `<tr>` tag of a table
1. `attributeSelectors` - key-value pairs where value is an CSS selector. from each match in `listSelector` a JSON object will be generated where keys will remain the same but values will be replaced with corresponding CSS selector results.

### Example

#### Request
```curl
curl -X POST \
  http://localhost:8080/getList \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "https://www.ss.com/lv/real-estate/flats/riga/all/",
    "listSelector": "#filter_frm table[align=center] tr",
    "attributeSelectors": {
        "url": ":nth-child(1) a | href",
        "location": ":nth-child(4)",
        "price": ":nth-child(9)"
    }
}'
```
#### Response
```json
[
    {
        "url": "/msg/lv/real-estate/flats/riga/centre/akljo.html",
        "location": "centrs Pērnavas 20",
        "price": "35 €/dienā"
    },
    {
        "url": "/msg/lv/real-estate/flats/riga/imanta/gedhl.html",
        "location": "Imanta Kurzemes pr. 24",
        "price": "240 €/mēn."
    },
    ...
]
```

## Usage - JSON object

Call `POST /getObject` endpoint to get JSON object.

Pass configuration JSON in POST body.
Configuration JSON consists of 3 parts:
1. `url` - URL to be called and parsed
1. `attributeSelectors` - key-value pairs where value is an CSS selector. from each match in `listSelector` a JSON object will be generated where keys will remain the same but values will be replaced with corresponding CSS selector results.

### Example

#### Request
```curl
curl -X POST \
  http://localhost:8080/getObject \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "https://www.ss.com/msg/lv/real-estate/flats/riga/centre/emfkl.html",
    "attributeSelectors": {
        "description": "#msg_div_msg ",
        "price": ".ads_price",
        "date": "#page_main td[valign=bottom] tbody tr:nth-child(2) td[align=right]",
        "meta": "#msg_div_msg .options_list"
    }
}
'
```
#### Response
```json
{
    "meta": "Pilsēta: Rīga Rajons: centrs Iela: Hospitāļu 23 Ērtības: Visas ērtības",
    "price": "700 €/mēn. (8.24 €/m²)",
    "description": "Сдается полностью меблированная квартира с хорошей планировкой и высококачественной отделкой в престижном проекте \"Шоколад\". Просторная квартира(85 кв. м) находится на 4 этаже дома с лифтом, наблюдением(консьерж) , в деловом центре города, с хорошей инфраструктурой. Оборудована всей необходимой техникой(холодильник, плита, духовка, стиральная, посудомоечная машины, телевизор). Планировка: гостиная-студия, 2 спальни, прихожая с гардеробом, 2 санузла(ванная комната с душевой кабиной и туалетом; гостевой туалет). Pilsēta: Rīga Rajons: centrs Iela: Hospitāļu 23 [Karte] Istabas: 3 Platība: 85 Stāvs: 4/7 Sērija: Jaun. Mājas tips: Paneļu - ķieģeļu Ērtības: Visas ērtības Cena: 700 €/mēn. (8.24 €/m²)",
    "date": "Datums: 07.08.2019 20:03"
}
```

## Attribute selector value chouce

By default the value is the text representation of tag contents, but it can be altered to html representation or a specific tag. 

For example `img.my_image | src` will find `img` tag and will return the value of `src` attribute. `div#main_contents | html` will return `div` tag's HTML contents, but `div#main_contents | text` or just `div#main_contents` will return plain text contents.

## Run local server

1. Install Vapor: https://docs.vapor.codes/3.0/install/macos/
1. Run the server on localhost: `vapor run`
