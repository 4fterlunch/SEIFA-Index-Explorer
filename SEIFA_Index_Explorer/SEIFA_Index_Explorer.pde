// SEIFA INDEX EXPLORER 1.0
// Michael Holmes 
// Student Number: 928428
// September 2018
//
// SEIFA data sourced from <http://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/2033.0.55.0012011?OpenDocument>

//-----------------------  Libraries used ------------------------

import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.marker.MarkerManager.*;
import java.util.List;
import de.fhpotsdam.unfolding.providers.OpenStreetMap;
import controlP5.*;
import java.util.Map;
import de.fhpotsdam.unfolding.ui.BarScaleUI;

//-----------------------  Global Constants ------------------------

final int MAX_LVL = 7;    /* set max zoom level */
final int MIN_LVL = 15;   /* set min zoom level */

final int DATA_LVL = 7;   /* optional setting to limit all geoJSON drawing */ 

//load geoJSON files (preprocessed)
final String LGA_FILE = "data/lgaVicSimpl.geojson";
final String SCHOOLS_FILE = "data/schoolsVicSummary.geojson";
final String CATCH_FILE = "data/analysis_files/catchmentSummary.geojson";

//set default focus position to start map
final Location melbCentral = new Location(-37.894484, 144.988461);  

//-----------------------  Global Variables ------------------------

UnfoldingMap map;                   /* main map object */
ControlP5 cp5;                      /* Controlp5 var for UI control */
CColor cColor;                      /* colour control for UI */
BarScaleUI barScale;                /* bar scale object */

//Control vars for interface
int currentChoro = 0;               /* Choropleth variable controller */
int currentSchool = 0;              /* point radius variable controller */
int currentZoom = MAX_LVL;          /* current zoom level control, default to max */
int bGAlpha = 80;                   /* Control for setting background alpha value*/

//data structs
SumStats activeChoroStats;          /* data structure for setting choropleth legend values */
SumStats activeRadStats;            /* data structure for setting radius legend values */
LGAData focusData;                  /* data var used for mouse over data */
List<LGAData> summaryData;          /* data list var used for summarising data */

//bools
boolean lgaToggle = true;           /* switch for drawing LGA layer */
boolean schoolsToggle = true;       /* switch for drawing schools layer */
boolean catchmentToggle = false;    /* switch for drawing catchment layer */
boolean focusOn = false;            /* checks is focus mode is on */

Marker focusMarker;                 /* Marker var used for mouse over data */
ExtManager focusLayer;
ExtManager schoolsLayer, catchLayer, lgaLayer;  /* my extended marker manager layers */

//misc
Tools tools;                         /* tools class for helper functions */
Location focus = new Location(melbCentral); /* used only for start up location */

//----------------------- Processing Functions ------------------------

void setup() {
  size(1200, 700);
  frameRate(30);
  println("SEIFA Index Explorer v1.0");
  println("Michael Holmes, September 2018");
  println("SEIFA data sourced from <http://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/2033.0.55.0012011?OpenDocument>");
  
  //initialise global vars
  tools = new Tools();
  focusData = new LGAData();                
  summaryData = new ArrayList<LGAData>();
  activeChoroStats = new SumStats();
  activeRadStats = new SumStats();
  
  //main map initialisation using openstreetmaps
  map = new UnfoldingMap(this, 0, 0, width - 250, 
    height, new OpenStreetMap.OpenStreetMapProvider());
  
  //set zoom limit parameters
  map.setZoomRange(MAX_LVL, MIN_LVL);
  
  //set inital start location and zoom level for map
  map.zoomAndPanTo(focus, 9);
  
  //set ui colours and barscale
  cColor = new CColor(0x99ffffff, 0x55ffffff, 0xffffffff, 0xffffffff, 0xffffffff);
  barScale = new BarScaleUI(this, map, 10, height - 20);
  
  //create the event despatcher
  MapUtils.createDefaultEventDispatcher(this, map);
  
  //load layers from directory
  lgaLayer = new ExtManager(loadMarkersFromJSON(LGA_FILE), MIN_LVL);
  schoolsLayer = new ExtManager(loadMarkersFromJSON(SCHOOLS_FILE), MIN_LVL);
  catchLayer = new ExtManager(loadMarkersFromJSON(CATCH_FILE), MIN_LVL);
  //prepare focus layer
  focusLayer = new ExtManager();
  
  //add layers to map object
  lgaLayer.setMap(map);
  schoolsLayer.setMap(map);
  catchLayer.setMap(map);
  focusLayer.setMap(map);
  
  //set styles for each layer
  lgaLayer.setStyle(color(255, 255, 255, 0), color(0, 0, 0, 100), 1); 
  schoolsLayer.setStyle(color(0, 0, 0,30), color(0,0,0, 200), 1);
  catchLayer.setStyle(color(255, 255, 255,0), color(247, 247, 247, 100), 1);
  
  //GUI
  cp5 = new ControlP5(this);
  setupGUI();
  
  //defaults for start
  cycleSchools();
  updateLegend();
  zoomBar(9);
}

void draw() {
  background(0);

  //lock panning if zoomed out, else free
  if (map.getZoomLevel() <= MAX_LVL) {
    map.setPanningRestriction(melbCentral, 500);
  } else {
    map.resetPanningRestriction();
  }

  //draw unfolding map
  map.draw();
  
  //soften basemap
  fill(255, 255, 255, bGAlpha);
  rect(0,0,width,height);
  
  //reduce load on drawing layers by drawing only once per second
  if (frameCount % 1 == 0) {
    if (lgaToggle && !focusOn) {
      lgaLayer.draw(); 
    } else if (focusOn) {
      focusLayer.draw();
    }
    if (catchmentToggle && !focusOn) {
      catchLayer.draw();  
    } 
    if (schoolsToggle) {
      schoolsLayer.draw();
    } 
  }
    //draw focus info (mouse pointer)
    if (focusMarker != null && mouseX < width-250) {
        setDataFromFocus();
        fill(30,20,20,150);
        rect(mouseX, mouseY - 60, 125, 60, 7);
        fill(255, 255, 255);
        text(focusData.name, mouseX + 5, mouseY - 50);
        text("IEO Score: " + focusData.IEOScore, mouseX + 5, mouseY - 35);
        text("Schools: " + focusData.numSchools, mouseX + 5, mouseY - 25);
        text("Pop per school: " + focusData.popPerSchool, mouseX + 5, mouseY - 15);   
    }
    
    //draw gui boxes
    noStroke();
    fill(30,20,20,150);
    rect(width - 250, 20, 250, 200, 7, 0, 0, 7);
    rect(width - 250, 225, 250, 200, 7, 0, 0, 7);
    rect(width - 150, 430, 150, 140, 7, 0, 0, 7);
    fill(255,255,255);
    
    //update zoom bar
    if (currentZoom != map.getZoomLevel()) {
      currentZoom = map.getZoomLevel();
      cp5.getController("zoomBar").setValue(map.getZoomLevel());
    }
    
    //map bits
    barScale.draw();                    //draw barscale
    stroke(2);
    
    //north arrow
    line(20, 35, 20, 10);
    line(18, 30, 22, 30);
    triangle(20, 10, 16, 20, 20, 21);
    
    //legend
    fill(0,0,0,30);
    stroke(0,0,0,200);
    strokeWeight(1);
    ellipse(width-120, 470, 2, 2); //min
    ellipse(width-120, 490, 10, 10); //max
    fill(94,60,153,20);
    stroke(0,0,0, 100);
    rect(width-130, 510, 20, 20, 4);  //min
    fill(94,60,153,235);
    rect(width-130, 540, 20, 20, 4) ;//max
    noStroke();
}


void mouseMoved() {
  if (frameCount % 4 == 0) {        //slow down checking to improve performance
    //load marker from layer into temporary marker var for mouseover
    if (lgaToggle && mouseX < width-250) {
      focusMarker = lgaLayer.checkMouseOver(mouseX, mouseY);
      }
    }
}

void mouseClicked() {
  /* if lga layer is on AND mouse is not over toolbar, select lga region */
  if (lgaToggle && mouseX < width-250) {
    focusMarker = lgaLayer.checkClick(mouseX, mouseY); 
  } 
}

//----------------------- Other Functions ------------------------

/* extract data from active focus Marker */
void setDataFromFocus() {
  focusData.name = focusMarker.getStringProperty("LGA_NAME11");
  focusData.numSchools = Float.parseFloat(focusMarker.getProperty("NumSchools").toString());
  focusData.popPerSchool = Float.parseFloat(focusMarker.getProperty("pop_school_num_ratio").toString());
  focusData.IEOScore = Float.parseFloat(focusMarker.getProperty("edem_Score").toString());
  focusData.IRSADScore = Float.parseFloat(focusMarker.getProperty("ad_Score").toString());
  focusData.IERScore = Float.parseFloat(focusMarker.getProperty("ec_Score").toString());
}

/* update summary GUI from LGA data struct */
void updateSummary(LGAData d) {
  if (d != null) {
    cp5.getController("numSchools").setValueLabel("Schools: " + d.numSchools);
    cp5.getController("population").setValueLabel("Population: " + d.pop);
    cp5.getController("popPerSchool").setValueLabel("Pop. Per School: " + d.popPerSchool);
    cp5.getController("IEOScore").setValueLabel("IEO Score: " + d.IEOScore);
    cp5.getController("IERScore").setValueLabel("IER Score: " + d.IERScore);
    cp5.getController("IRSADScore").setValueLabel("IRSAD Score: " + d.IRSADScore);
    
  }
    
}

/* loads a geoJSON file and returns as a list of markers */
public List<Marker> loadMarkersFromJSON(String location) {
  //load in lga features
  print("[INFO] loading markers: " + location + "...");
  List<Feature> f = GeoJSONReader.loadData(this, location);
  println("done!");

  return MapUtils.createSimpleMarkers(f);
}

/* update zoom bar */
public void zoomBar(int value) {
  if(currentZoom != value){
    map.zoomTo(value);
    currentZoom = value;
  }

}

/* handle LGA layer toggle on/off */
public void lgaToggle() {
  lgaToggle = lgaToggle ? false : true;
}

/* handle schools layer toggle on/off */
public void schoolsToggle() {
  schoolsToggle = schoolsToggle ? false : true;
}

/* handle  catchment toggle on/off */
public void catchmentToggle() {
  catchmentToggle = catchmentToggle ? false : true;
}

/* runs summarise function */
public void summarise() {
  if (!focusOn) {
    LGAData x = new LGAData();  //temp
    focusLayer.addMarkers(lgaLayer.getSelected()); //get selected markers
    focusOn = true;
    bGAlpha = 150;
    List<Marker> temp = focusLayer.getMarkers();  //load markers into temp
    for (Marker m : temp) {
      LGAData d = new LGAData();
      d = tools.markerToLGAData(m);                //use tool to extract marker data
      
      //summation for data
      x.numSchools += d.numSchools;
      x.pop += d.pop;
      x.popPerSchool += d.popPerSchool;
      x.IEOScore += d.IEOScore;
      x.IRSADScore += d.IRSADScore;
      x.IERScore += d.IERScore;
    }
    
    //calculate averages
    x.popPerSchool = x.popPerSchool / temp.size();
    x.IEOScore = x.IEOScore / temp.size();
    x.IRSADScore = x.IRSADScore / temp.size();
    x.IERScore = x.IERScore / temp.size();
    
    //pass in and update
    updateSummary(x);
 
  } else {
    //otherwise clear and clean
    focusOn = false;
    focusLayer.clearMarkers();
    bGAlpha = 80;
  }
}

/* clears the selected markers */
public void clearSelection() {
  if (lgaToggle)
    lgaLayer.deselectAll();
  else if (catchmentToggle)
    catchLayer.deselectAll();
  focusLayer.clearMarkers();       //clear selection from focus
  focusOn = false;
  updateSummary(new LGAData());    //set summary to 0;
}

/* handle the choropleth cycle */
public void cycleChoro() {
  if (currentChoro < 5) {
    currentChoro += 1;
  } else {
    currentChoro = 0;
  }
  
  switch (currentChoro) {
    case 0: lgaLayer.setStyle(color(255, 255, 255, 0), color(0, 0, 0, 100), 1);
            cp5.getController("activeLGA").setValueLabel("None");
            activeChoroStats = new SumStats();
            break;
    case 1: activeChoroStats = lgaLayer.setChoropleth("edem_Score", 94,60,153, false);
            cp5.getController("activeLGA").setValueLabel("LGA IEO Score");
            break;
    case 2: activeChoroStats = lgaLayer.setChoropleth("ad_Score", 94,60,153, false);
            cp5.getController("activeLGA").setValueLabel("LGA IRSADScore");
            break;
    case 3: activeChoroStats = lgaLayer.setChoropleth("ec_Score", 94,60,153, false);
            cp5.getController("activeLGA").setValueLabel("LGA IER Score");
            break;
    case 4: activeChoroStats = lgaLayer.setChoropleth("ad_Usual Resident Population", 94,60,153, false);
            cp5.getController("activeLGA").setValueLabel("LGA Population");
            break;
    case 5: activeChoroStats = lgaLayer.setChoropleth("pop_school_num_ratio", 94,60,153, true);
            cp5.getController("activeLGA").setValueLabel("LGA Population per School");
            break;
    default: break;
    }
    updateLegend();
}

/* handle the point radius cycle */
public void cycleSchools() {
  if (currentSchool < 5) {
    currentSchool += 1;
  } else {
    currentSchool = 0;
  }
  
  switch (currentSchool) {
    case 0: schoolsLayer.setPointRadius(2); 
            cp5.getController("activeSchools").setValueLabel("None");
            activeRadStats = new SumStats();
            break;
    case 1: activeRadStats = schoolsLayer.setRadiusToValue("meanedem_Score", false);
            cp5.getController("activeSchools").setValueLabel("Catchment Mean IEO Score");
            break;
    case 2: activeRadStats = schoolsLayer.setRadiusToValue("meanad_Score", false);
            cp5.getController("activeSchools").setValueLabel("Catchment Mean IRSAD Score");
            break;
    case 3: activeRadStats = schoolsLayer.setRadiusToValue("meanec_Score", false);
            cp5.getController("activeSchools").setValueLabel("Catchment Mean IER Score");
            break;
    case 4: activeRadStats = schoolsLayer.setRadiusToValue("mean_Usual Resident Population", false);
            cp5.getController("activeSchools").setValueLabel("Catchment Mean Population");
            break;
    case 5: activeRadStats = schoolsLayer.setRadiusToValue("minedem_Score", false);
            cp5.getController("activeSchools").setValueLabel("Catchment Minimum IEO Score");
            break;
    default: break;
    }
    updateLegend();
}

void updateLegend() {
  cp5.getController("radMin").setValueLabel(String.valueOf(activeRadStats.min));
  cp5.getController("radMax").setValueLabel(String.valueOf(activeRadStats.max));
  cp5.getController("choroMin").setValueLabel(String.valueOf(activeChoroStats.min));
  cp5.getController("choroMax").setValueLabel(String.valueOf(activeChoroStats.max));
}

/* initialises all ControlP5 GUI */
public void setupGUI() {
  cp5.addSlider("zoomBar")
    .setPosition(width - 230, 50)
    .setSize(190,20)
    .setRange(MAX_LVL, MIN_LVL)
    .setNumberOfTickMarks(MIN_LVL - MAX_LVL)
    .setLabel("Zoom")
    .setColor(cColor);
  cp5.addToggle("lgaToggle")
    .setPosition(width - 230, 90)
    .setSize(50, 20)
    .setLabel("Show LGA")
    .setColor(cColor);
  cp5.addToggle("schoolsToggle")
    .setPosition(width - 160, 90)
    .setSize(50, 20)
    .setLabel("Show Schools")
    .setColor(cColor);
  cp5.addToggle("catchmentToggle")
    .setPosition(width - 90, 90)
    .setSize(50, 20)
    .setLabel("Show Catchment")
    .setColor(cColor);
  cp5.addButton("summarise")
    .setSize(80, 20)
    .setPosition(width - 220, 250)
    .setLabel("Summarise")
    .setColor(cColor);
  cp5.addButton("clearSelection")
    .setPosition(width - 110, 250)
    .setSize(80, 20)
    .setLabel("Clear Selection")
    .setColor(cColor);
  cp5.addTextlabel("header")
    .setText("SEIFA Index Explorer Victoria")
    .setPosition(width-200, 30);
  cp5.addTextlabel("header2")
    .setText("Data Analysis")
    .setPosition(width-160, 230);
  cp5.addTextlabel("north")
    .setText("N")
    .setPosition(14, 37)
    .setColor(color(0,0,0,100));
   
  cp5.addButton("cycleChoro")
    .setSize(80, 20)
    .setPosition(width - 230, 150)
    .setLabel("Cycle LGA")
    //.setFont(fontSmall)
    .setColor(cColor);
  cp5.addTextlabel("activeLGA")
    .setText("none")
    .setPosition(width-145, 155);
  cp5.addButton("cycleSchools")
    .setSize(80, 20)
    .setPosition(width - 230, 180)
    .setLabel("Cycle Schools")
    //.setFont(fontSmall)
    .setColor(cColor);
  cp5.addTextlabel("activeSchools")
    .setText("Catchment Mean IEO Score")
    .setPosition(width-145, 185);
  
    
    //set data analysis
  cp5.addTextlabel("dataSub")
    .setText("Choose at least one LGA to summarise")
    .setPosition(width-230, 290);
  
  cp5.addTextlabel("numSchools")
    .setText("Schools: ")
    .setPosition(width-230, 310);
  cp5.addTextlabel("population")
    .setText("Population: ")
    .setPosition(width-230, 320);
  cp5.addTextlabel("dataSub2")
    .setText("LGA Averages: ")
    .setPosition(width-230, 340);
  cp5.addTextlabel("popPerSchool")
    .setText("Pop. per School: ")
    .setPosition(width-230, 360);
  cp5.addTextlabel("IEOScore")
    .setText("IEO Score: ")
    .setPosition(width-230, 370);
  cp5.addTextlabel("IRSADScore")
    .setText("IRSAD Score: ")
    .setPosition(width-230, 380);
  cp5.addTextlabel("IERScore")
    .setText("IER Score: ")
    .setPosition(width-230, 390);
  //legend
  cp5.addTextlabel("legHeading")
    .setText("Legend")
    .setPosition(width-90, 435);
  cp5.addTextlabel("radMin")
    .setText("min")
    .setPosition(width-100, 465);
  cp5.addTextlabel("radMax")
    .setText("max")
    .setPosition(width-100, 485);
  cp5.addTextlabel("choroMin")
    .setText("min")
    .setPosition(width-100, 515);
  cp5.addTextlabel("choroMax")
    .setText("max")
    .setPosition(width-100, 545);
}

/* data structure for LGA values */
class LGAData {
  String name;
  float numSchools;
  float pop;
  float popPerSchool;
  float IEOScore;
  float IRSADScore;
  float IERScore;
  
  public LGAData() { }
}





