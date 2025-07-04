# Projekat: IRThermo Click 5V beskontaktni senzor

Ovaj projekat prikazuje kako integrisati MLX90614 IR senzor za beskontaktno mjerenje temperature sa DE1-SoC pločom koristeći Buildroot za kreiranje Linux sistema i I2C interfejs za komunikaciju.

## Preduslovi

- Linux sistem (za Buildroot i kompajliranje)
- `arm-linux-gcc` cross-compiler
- USB-UART konekcija ili mrežna konekcija sa DE1-SoC
- SD kartica (za boot)
- SSH podešen (javnim/privatnim ključem)

## 1. Hardware

U ovom projektu koristi se sledeći hardver:

- **DE1-SoC** razvojna ploča (Cyclone V SoC)
  
  ![ploca](https://github.com/user-attachments/assets/98e4b47e-fd19-4f40-b9b6-258c79075c75)
  <p>Izgled ploce</p>
- **MLX90614** beskontaktni IR temperaturni senzor
![irthermo-5v-click-thickbox_default-12x](https://github.com/user-attachments/assets/86854a0c-fe79-47e7-937a-7e47b9df6a92)
  <p align=center>Izgled senzora</p>
- **I2C** magistrala za komunikaciju između senzora i HPS-a
- **Level shifter** za usklađivanje naponskih nivoa (3.3V ↔ 5V)
  ![s-l1200](https://github.com/user-attachments/assets/52e4a987-4d03-4e4b-8047-70fda9df716a)
  <p align=center>Izgled level shifter-a</p>
- Protobord (breadboard) kao i odgovarajući broj kablića (vezica) za povezivanje
- Potrebna je fizička povezanost između FPGA i HPS strane putem odgovarajućeg `.rbf` fajla - nalazi se u ovom repozitorijumu

### 1.1 DE1SOC pinovi

![image](https://github.com/user-attachments/assets/30e07a73-715e-49fc-ad33-30403f94cf40)
<p align=center>Raspored definisanih pinova</p>

  Lijevi pinovi (u daljem tekstu gpio0) se pretezno koriste i to na sljedeci nacin. Prvi pin brojeći
odozgo prema dolje se koristi za *SCL* signal. Odmah do njega nalazi se pin za *SDA* signal. Na šestom pinu se nalazi
napon od 5V koji ćemo koristiti na level shifter-u da bi dobili odgovarajuće signale na senzoru. Odozdo
šesti lijevi pin je naponski pin koji daje 3.3V i takođe se koristi kod level shifter-a. Odmah do njega nalazi se 
pin koji predstavlja uzemljenje. Na desnoj strani koristi se samo jedan pin i to je sedmi desni odozgo prema dolje i služi za wakeup (označeni brojem 1 u žutom pravouganiku).

### 1.2 Level shifter pinovi

  Sam shifter je podijeljen u dva dijela *LV* i *HV*. U konkretno slucaju neophodni su nam vanjski parovi pinova (lv-hv)
kao i oba unutrašnja para. Vanjski parovi sluze za povezivanje *SCL* i *SDA* dok unutrušnji za 3.3V i 5V. Takođe imamo
i dva pina uzemljenja koji su u međusobnom kratkom spoju pa možemo posmatrati kao da su jedan.

![10633d1236880a914ca4b02179b64b1d13e8597b](https://github.com/user-attachments/assets/025c68db-f07a-40b9-87d6-054d5561be5e)
<p align=center>Šema rada level shifter-a</p>

Ovaj sklop se koristi za dvosmjerno prevođenje signala između dva različita logička napona, npr. sa **3.3V** na **5V** i obrnuto. Sastoji se od jednog **N-kanalnog MOSFET-a (BSS138)** i dva **pull-up otpornika od 10kΩ**.

#### Konekcije:
- **Source** → TX_LV (niskonaponska strana)
- **Gate** → direktno na 3.3V (LV)
- **Drain** → TX_HV (visokonaponska strana)
- **R3 (10kΩ)** između TX_LV i 3.3V
- **R4 (10kΩ)** između TX_HV i 5V

---

#### Kako funkcioniše:

##### Kada uređaj sa 3.3V šalje logičku “1”:
- TX_LV = 3.3V
- Gate = 3.3V → Vgs = 0V → MOSFET isključen
- TX_HV se povlači na 5V preko R4 → logička “1” vidljiva na 5V strani

##### Kada uređaj sa 3.3V šalje logičku “0”:
- TX_LV = 0V
- Gate = 3.3V → Vgs = 3.3V → MOSFET uključen
- TX_HV se povlači na 0V preko MOSFET-a → logička “0” na 5V strani

---

##### Kada uređaj sa 5V šalje logičku “1”:
- TX_HV = 5V
- Drain = 5V, Source ≈ 3.3V → Vgs ≈ -1.7V → MOSFET isključen
- TX_LV se povlači na 3.3V preko R3 → logička “1” vidljiva na 3.3V strani

##### Kada uređaj sa 5V šalje logičku “0”:
- TX_HV = 0V
- Drain = 0V → Vgs = 3.3V → MOSFET uključen
- TX_LV se povlači na 0V preko MOSFET-a → logička “0” na 3.3V strani




### 1.3 IRTHERMO CLICK 5V

  Konkretan senzor se sastoji od 16 pinova od kojih većina nije ni konfigurisana (NC). Nama su potrebna
donja 4 desne strane  (GND, 5V, SDA, SCL). 

![image](https://github.com/user-attachments/assets/804bf137-f96c-410f-84a0-cc928c5cd964)

<p align=center>Šema senzora</p>


### 1.4 Povezivanje

  Prvi korak prilikom fizičkog povezivanja je da na željeno mjesto na protoboard-u "ubodemo" shifter i senzor.
  Sljedeći korak je povezivanje ploče i shiftera tako da kreiramo sljedeće parove veza:

● *SCL* pin sa ploče vezujemo na jedan vanjski pin *LV* strane (oznaka *TXI*)  
● *SDA* pin sa ploče vezujemo na drugi vanjski pin *LV* strane (oznaka *TXI*)  
● 3.3V pin sa ploče vezujemo na gornji unutrašnji pin *LV* strane (oznaka *LV*)  
● *GND* pin sa ploče vezujemo na donji unutrašnji pin *LV* strane (oznaka *GND*)  
● 5V pin sa ploče vezujemo na neoznačeni pin *HV* strane  
● *Wakeup* pin sa ploče vezuje se na isti pin kao i *SDA*  

Ovime smo povezali našu ploču i shifter. Sljedeći korak je da vežemo naš shifter (*HV strana*) i sam senzor. Postupak je sljedeći:

● *TXO* pin koji predstavlja parnjaka *SCL* pinu vodimo na *SCL* pin senzora  
● 5V pin *HV* strane dovodimo na 5V pin samog senzora čime smo mu obezbijedili odgovarajući napon  
● *GND* pin dovodimo na *GND* pin senzora  
● *TXO* pin koji predstavlja parnjaka *SDA* pinu dovodimo na *SDA* pin senzora  

Ovime smo obezbijedili fizičko vezivanje između senzora, shiftera i ploče.  

![Schema](https://github.com/user-attachments/assets/e52df8d2-9e8f-4a77-b9b5-fddfa4a1fb54)


<p align=center>Grafički prikaz povezivanja</p>
  
        

## 2. Buildroot

Buildroot se koristi za kreiranje prilagođenog Linux sistema za DE1-SoC ploču.
> [!IMPORTANT]
> Ovo nije kompletan buildroot folder nego samo specifični elementi koji su korišteni radi ovogućavanja čitanja temperature, stoga je neophodno izvršiti prilagođenje vlastitog.



Kloniraj repozitorijum sa Buildroot konfiguracijom:
   ```
   git clone https://github.com/Brada45/Projekat_URS.git
   cd buildroot
  ```
Dati folder ima ovakvu strukturu  
 ```
├── buildroot  
│   ├── board  
│   │   └── terasic  
│   │       └── de1soc_cyclone5  
│   │           ├── boot.cmd  
│   │           ├── boot-env.txt  
│   │           ├── boot.scr  
│   │           ├── de1_soc_defconfig  
│   │           ├── de1-soc-handoff.patch  
│   │           ├── genimage.cfg  
│   │           ├── rootfs-overlay  
│   │           │   ├── etc  
│   │           │   │   └── systemd  
│   │           │   │       └── network  
│   │           │   │           └── 70-static.network  
│   │           │   └── root
│   │           │       └── .ssh  
│   │           │           └── authorized_keys  
│   │           ├── socfpga_cyclone5_de1_soc.dts  
│   │           └── socfpga.rbf  
│   ├── output
│   │   └── linux-socfpga-6.1.38-lts
│   │        └── .config  
│   └── package  
│       ├── canopen  
│       │   ├── canopen.mk  
│       │   └── Config.in  
│       └── Config.in  
 ```     
Sada ćemo preći bitne fajlove/foldere u ovom direktorijumu:  
  ● boot.cmd, boot-env.txt, boot.scr - fajlovi koji služe za definisanje načina boot-ovanja sistema  
  ● de1_soc_defconfig - txt fajl koji prikazuje sve uključene opcije u sistemu  
  ● de1-soc-handoff.patch - *zakrpa* koja služi za konfiguraciju *SPL* i *U-Boot*  
  ● rootfs-overlay - koristi se za kreiranje stalnih osobina sistema (u konkretnom slučaju koristi se da se podesi *ip* adresa mrežnog interfejsa i da se *prebaci* javni kljuc koji omogućava ssh komunikaciju)  
  ● socfpga_cyclone5_de1_soc.dts - *device tree* fajl koji se koristi za opis hardverske konfiguracije sistema (kojim perifernim uređajima npr. I2C senzori, UART, GPIO, SPI, itd. operativni sistem (kernel) ima pristup i kako su oni povezani)  
  ● socfpga.rbf - fajl koji omogućava komunikaciju između fpga i hps dijela de1-soc ploče  
  ● genimage.cfg je fajl kojim opisujemo strukturu naše *SD* kartice i šta će se sve nalaziti na njoj  
U *output/linux-socfpga-6.1.38-lts* nalazi se fajl .config u kojem se čuvaju specifičnosti vezane za kernel (koji drajveri su uključeni i slično, u konkretnom slučaju se između ostalog nalazi se drajver i za naš senzor)  

> [!NOTE]
> Moguće je kopirati *txt* fajlove u vlastite kako bi se minimizirao postupak ručnog uključivanja/isključivanja opcija.

## 3. Soruce

*UNIX* filozofija je *Sve je fajl* zbog toga se u datom *source* kodu otvara fajl na određenoj magistrali. Taj fajl se dobija adekvatnim *vezivanjem drajvera* i odgovara senzora. U konkretnom slučaju 
nalazi se na putanji */sys/bus/iio/devices/iio:device0/in_temp_object_raw*. Kada pročitamo ovaj fajl dobićemo neku vrijednost (u za sobnu temperaturu oko 15000). Adekvatnim konvertovanjem (množenjem sa 0.02, a potom oduzimanjem sa
273.15) dobijamo vrijednost u stepenima Celzijusa. Čitanje temperature se izvršava periodično svake sekunde.  
  
Dati kod je potrebno adekvatno kroskompajlirati komandom 
```
  arm-linux-gcc read_temp -o read_temp
```
nakon čega ga je neophodno prebaciti na neki način na ploču i započeti izvršavanje.

## 4 Bitne napomene

### 4.1 DTS fajl
U našem dts je neophodno da se nalazi sljedeći čvor
```
&i2c2 {
        status = "okay";
        clock-frequency = <100000>;

        ir_thermo@5a {
                compatible = "melexis,mlx90614";
                reg = <0x5a>;
                wakeup-gpios = <&gpio_altr 1 0>;
        };
};
```
čime postižemo sljedeće. Pali se i2c2 magistrala preko koje senzor komunicira sa pločom, potom se podešava frekfencija kojom se komunicira. Podčvor predstavlja konkretan drajver koji služi za *rad* sa senzorom gdje imamo dvije 
bitne opcije compatible (parametar po kojem se pronalazi drajver), reg je adresa na kojoj senzor odgovara i na kojoj će se *vezati* drajver. Treća opcija je proizvoljna i nije heophodna za ispravan rad senzora i predstavlja informaciju
o tome da li je definisan i ako jeste gdje, *wakeup gpio* pin.

## 4.2 Linux kernel
 Da bi išta imalo smisla neophodno je da uključimo odgovarajući drajver. To postižemo tako što se pozicioniramo u originalni buildroot folder i pokrenemo komandu
```
  make linux-menuconfig
```
a potom  pratimo sljedeću strukturu 
```
Device Drivers --->
    -> Industrial I/O support --->
        -> Temperature sensors --->
            <*> Melexis MLX90614 contactless infrared thermometer
```
nakog čega je potrebno ponovo *mejkovati* kernel i sam linux. Ovo se može uraditi i ručnim kopiranjem *.config* fajla iz *linux-socfpga-6.1.38-lts* foldera ili samo dijela vezanog za senzor.

## 4.3 Prebacivanje izvršnog fajla na ploču
U ovom teksu smo spominjali da postoji mnogo načina prebacivanja fajlova između razvojnog i ciljnog uređaja. U ovu svrhu koristimo gore spomenuti rootfs-overlay. Fajl *70-static.network* čuva podatke o ip adresi mrežnog
interfejsa ploče, dok authorized_keys predstavlja javni ključ koji je neophodan za sigurnu komunikaciju. U konkretnom slučaju je postavljeno da je ip adresa ploče *192.168.23.100* i pokrećemo komandu:
```
scp -O -i [putanja/do/privatnog/ključa] read_temp root@192.168.23.100:/home
```
Neophodno je spomenuti da se nalazimo u folderu *source*. Ovom komandom smo prebaci naš izvršni fajl u home folder naše ciljne platforme.  
Preostaje nam samo još da se prebacimo u taj folder i pokrenemo našu aplikaciju za mjerenje temperature.

## 5. Rad sa pločom

Nakon paljenja ploče i adekvatnog povezivanja (npr serijski port sa sljedećim podacima Serial line: COMX, speed: 115200) vidjećemo da se sistem *boot-ovao* i dobićemo poruku
```
DE1-SoC on ETFBL
etfbl login:
```
ovdje je neophodno da unesemo *root* osim ako taj podatak nismo mijenjali. Nakon unosa uspjesno smo se ulogovali na sistem i imamo punu kontrolu nad njim. Pod pretpostavkom da smo prebacili naš kod za mjerenje temperature na ploču možemo izvršiti sljedeće komande i pokrenuti naš program.
```
cd ../home
./read_temp
```

Sada kad smo pokrenuli program, ako smo sve uradili kako treba, trebali bi dobijati ovakav ispis:
```
Temperatura: 26.37 °C
Temperatura: 26.41 °C
Temperatura: 26.43 °C
```

## 6. Kako sistem radi

- Buildroot generiše prilagođeni Linux image koji uključuje drajver za MLX90614 senzor.
- DTS fajl opisuje fizičko povezivanje senzora na I2C2 magistralu.
- Nakon boota, kernel automatski učita drajver i izloži senzor kao fajl u `/sys` sistemu.
- Korisnička aplikacija `read_temp` čita vrijednosti iz fajl sistema i konvertuje ih u stepeni Celzijusa.

