# Hardware Requirements für Agentic Factory

## Zielkonfiguration (Optimal)

| Komponente | Anforderung | Grund |
|------------|-------------|-------|
| **GPU** | RX 6900 XT (16GB VRAM) | Local Model Execution (alle 3 Agenten gleichzeitig) |
| **CPU** | 8+ Cores | Parallel Processing |
| **RAM** | 32 GB | OS + Docker (Plane) + Python |
| **Disk** | 256 GB NVMe | Model Cache + Docker Images |
| **OS** | Windows 11 / Linux | ROCm/CUDA Support |

---

## Minimale Anforderungen (Fallback)

Wenn du nicht die volle Hardware hast:

### Szenario 1: Schwache GPU / CPU-Only

```
GPU:  None oder iGPU
CPU:  4+ Cores
RAM:  16 GB
→ Funktioniert, aber LANGSAM für Coder + Tester parallel
   Workaround: Sequential Model Execution (nacheinander)
```

**Performance:** 5-10x langsamer als GPU

### Szenario 2: Mid-Range GPU (z.B. RTX 3060, 12GB VRAM)

```
GPU:  NVIDIA RTX 3060 (12GB)
CPU:  6+ Cores
RAM:  24 GB
→ Funktioniert, aber nur 2 Modelle parallel
   Workaround: Reviewer kann auf CPU laufen
```

**Performance:** 2-3x langsamer als RX 6900 XT

### Szenario 3: Windows AMD mit ROCm-Problemen

```
Problem: AMD GPUs haben experimentellen ROCm-Support in Ollama
Lösung 1: Wechsel zu LM Studio (besserer Vulkan-Support)
Lösung 2: WSL2 + Linux ROCm (kompliziert)
Lösung 3: CPU-Only (langsamste Option)
```

---

## Modell-Größen & VRAM-Bedarf

### Lokale Modelle

| Modell | Größe | VRAM Needed | Performance |
|--------|-------|------------|-------------|
| phi3:mini | 2.7B | 2-3 GB | Schnell (Code Review) |
| llama3.1:8b | 8B | 5-6 GB | Mittel (Testing) |
| qwen2.5-coder:14b | 14B | 10-12 GB | Komplex (Full Coding) |
| **Alle 3 parallel** | — | **16+ GB** | Ideal für Fabrik |

### Alternativen für schwache Hardware

```bash
# Kleinere Modelle (schneller, weniger VRAM)
ollama pull phi3:mini         # 2.7B, 2 GB VRAM ← für CPU
ollama pull deepseek-coder:6.7b  # 6.7B, 6-7 GB ← mittler Weg

# Größere Modelle (besser, mehr VRAM)
ollama pull neural-chat:13b   # 13B, 10-11 GB
ollama pull mistral:7b        # 7B, 4-5 GB ← schnell
```

---

## GPU-Kompatibilität nach Hersteller

### NVIDIA (Best Case)

```bash
Modelle: RTX 4090, 3090, 3060 Ti, 4070
Support:  Full CUDA
Ollama:   Perfekt
Prognose: ✅ Alles funktioniert out-of-the-box
```

### AMD (Tricky)

```bash
Modelle: RX 7900 XTX, 6900 XT, 6800 XT
Support:  Experimental ROCm (Windows), Good ROCm (Linux)
Ollama:   Funktioniert, aber nicht garantiert
Prognose: ⚠️ Teste mit `ollama ps` nach dem Starten

Fallback: LM Studio mit Vulkan Backend (oft besser)
```

### Intel Arc (Nicht empfohlen)

```bash
Support:  Intel oneAPI (sehr neu)
Ollama:   Noch nicht offiziell unterstützt
Prognose: ❌ Erwarte CPU-Only Fallback
```

### Apple Silicon (M1/M2/M3)

```bash
Support:  Exzellent (Metal)
Ollama:   Native Support
Prognose: ✅ Funktioniert sehr gut
```

---

## Performance-Benchmarks (Observed)

### RX 6900 XT (16GB) - TARGET SETUP

```
phi3:mini        → ~200 tokens/sec
llama3.1:8b      → ~80 tokens/sec
qwen2.5-coder:14b → ~40 tokens/sec (parallel limited)
```

### RTX 3090 (24GB)

```
phi3:mini        → ~250 tokens/sec
llama3.1:8b      → ~120 tokens/sec
qwen2.5-coder:14b → ~60 tokens/sec
```

### CPU-Only (8-Core i7)

```
phi3:mini        → ~10 tokens/sec (😵)
llama3.1:8b      → ~3 tokens/sec (nicht praktisch)
qwen2.5-coder:14b → ~1 token/sec (unmöglich)
```

**Fazit:** GPU ist nicht optional für Production Use!

---

## Kosten-Abschätzung (2024/2025)

### Option A: RX 6900 XT (RECOMMENDED)

```
GPU:       €400-500
CPU (8c):  €150-200
RAM (32GB): €100-150
SSD (256GB): €30-40
Gesamt:    ~€700-900 einmalig
Laufende:  €0 (nur Strom ~50W idle)
```

### Option B: NVIDIA RTX 3090

```
GPU:       €800-1200
Rest:      ~€300
Gesamt:    ~€1100-1500 einmalig
```

### Option C: LM Studio (Fallback)

```
Hardware:  Beliebig (auch schwach)
Software:  LM Studio ($free/$pro)
Nachteil:  Weniger automatisiert, UI-basiert
```

---

## Checkliste vor dem Start

- [ ] GPU mit `nvidia-smi` oder `rocm-smi` sichtbar?
- [ ] 32+ GB RAM verfügbar? (`free -h`)
- [ ] 256 GB SSD Platz? (`df -h`)
- [ ] Ollama installiert? (`ollama --version`)
- [ ] Erstes Modell lädt? (`ollama run phi3`)
- [ ] GPU wird genutzt? (`ollama ps`)
- [ ] Docker/Docker Compose installiert? (`docker --version`)

---

## Hilfreiche Befehle

```bash
# Hardware Info
uname -a                      # OS und Kernel
lscpu                        # CPU Details
free -h                      # RAM Auslastung
df -h                        # Disk Space
nvidia-smi                   # NVIDIA GPU Status
rocm-smi                     # AMD GPU Status

# Ollama Debug
ollama ps                    # Laufende Modelle + GPU Auslastung
ollama list                  # Heruntergeladene Modelle
ollama run phi3 "test"       # Schneller GPU Test
OLLAMA_DEBUG=1 ollama run phi3  # Mit Debug-Output
```

---

## Mein Setup (Referenz)

```yaml
OS:       Windows 11 Pro
GPU:      RX 6900 XT 16GB
CPU:      Ryzen 7 5800X3D (8c/16t)
RAM:      32 GB DDR4
Disk:     1TB NVMe Gen4
Ollama:   Latest (mit ROCm)
Docker:   Desktop (WSL2)
Result:   ✅ All 3 local agents parallel, φ3 review in <2s
```

---

**Fazit:** Starten mit dem, was du hast. GPU ist der Bottleneck. Wenn CPU-Only, nutze Cloud für mehr Komplexität.
