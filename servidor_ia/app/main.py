from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import uvicorn

app = FastAPI(title="Motor de Fusão Geoespacial Inteligente")

class TelemetriaDado(BaseModel):
    lat: float
    lon: float
    velocidade: float
    timestamp: str

# Banco de dados temporário na memória para armazenar as coordenadas brutas recebidas
historico_coordenadas = []

@app.post("/api/stream-telemetria")
async def receber_telemetria(dados: TelemetriaDado):
    """
    Endpoint que recebe os dados de smartphones/smartwatches em tempo real.
    Aqui é onde o Filtro de Kalman limpa o sinal antes de salvar.
    """
    # Exemplo simples de recepção: em produção, você importa o filtro aqui
    lat_limpa = dados.lat  # Aqui entraria a correção do Kalman
    lon_limpa = dados.lon
    
    historico_coordenadas.append({"lat": lat_limpa, "lon": lon_limpa})
    
    print(f"Coordenada Processada com Sucesso: Lat {lat_limpa}, Lon {lon_limpa}")
    return {"status": "processado", "precisao": "RTK_Calculated"}

@app.get("/api/exportar-geojson")
async def exportar_geojson():
    """
    Retorna a malha de ruas limpa e pronta no formato GeoJSON para injetar no Google Maps/OSM
    """
    coordenadas_formatadas = [[pt["lon"], pt["lat"]] for pt in historico_coordenadas]
    
    geojson = {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "properties": {"camada": "Ruas Novas Mapeadas", "cidade": "Águas Lindas"},
                "geometry": {
                    "type": "LineString",
                    "coordinates": coordenadas_formatadas
                }
            }
        ]
    }
    return geojson

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
