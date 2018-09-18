// extention class for Marker Manager, adding functionality for this project
// Michael Holmes, September 2018
// student number: 928428

import java.util.Map;

class ExtManager extends MarkerManager {
  
  private final int DEFAULT_DRAW = 10;    //default draw level if not set
  private int drawLevel;                  //the draw level control
  
  public ExtManager(List<Marker> m) {
    super(m);
    drawLevel = DEFAULT_DRAW;
  }
  
  public ExtManager(List<Marker> m, int drawLevel) {
    super(m);
    this.drawLevel = drawLevel;
  }
  
  public ExtManager() {
    super();
    drawLevel = DEFAULT_DRAW;
  }

  /* creates choropleth shape map for a set of markers
   * based on an attribute and base colour, can be inverted
   */
  public SumStats setChoropleth(String attribute, int r, int g, int b,  boolean invertRamp) {
    List<Marker> temp = this.getMarkers();
    SumStats stats = tools.getSummaryStats(temp, attribute);
    
    println("min:",stats.min," max:", stats.max);    //check min, max
    
    /* now create the alpha value mapping based on value */
    for (Marker m : temp) {
      Object o = m.getProperty(attribute);
      float attVal = Float.parseFloat(o.toString());
      // check for invert, map value, min, max, aplha low, alpha High
      float alpha = invertRamp ? map(attVal, stats.max, stats.min, 20, 235) 
        : map(attVal, stats.min, stats.max, 20, 235);
      m.setColor(color(r,g,b,alpha));
    } 
    
    this.setMarkers(temp);
    
    return stats;
  }
  
  /* sets fill, stroke and stroke weight all at once */
  public void setStyle(color fillColor, color strokeColor, int strokeWeight) {
    List<Marker> temp = this.getMarkers();
      
    for (Marker m : temp) {
      m.setColor(fillColor);
      m.setStrokeColor(strokeColor);
      m.setStrokeWeight(strokeWeight);
    }
    this.setMarkers(temp);
  }
  
  /* set fill for all */
  public void setAllColor(color c) {
    List<Marker> temp = this.getMarkers();
      
    for (Marker m : temp) {
      m.setColor(c);
    }
    this.setMarkers(temp);
  }
  /* set stroke colour for all */
  public void setAllStrokeColor(color c) {
    List<Marker> temp = this.getMarkers();
      
    for (Marker m : temp) {
      m.setStrokeColor(c);
    }
    this.setMarkers(temp);
  }
  
  /* set weight for all */
  public void setAllStrokeWeight(int w) {
    List<Marker> temp = this.getMarkers();
      
    for (Marker m : temp) {
      m.setStrokeWeight(w);
    }
    this.setMarkers(temp);
  }
  
  /* sets point radius for all */
  public void setPointRadius(float r) {
    List<Marker> temp = this.getMarkers();
    
    for (Marker m : temp) {
      ((SimplePointMarker) m).setRadius(r);
    }
    this.setMarkers(temp);
  }
  
  /* sets point radius for all based on a value, can be inverted */
  public SumStats setRadiusToValue(String a, boolean invert) {
  List<Marker> temp = this.getMarkers();
    SumStats stats = tools.getSummaryStats(temp, a);
    
    println("min:",stats.min," max:", stats.max);    //check min, max
    
    /* now create the alpha value mapping based on value */
    for (Marker m : temp) {
      Object o = m.getProperty(a);
      float attVal = Float.parseFloat(o.toString());
      // check for invert, map value, min, max, aplha low, alpha High
      float rad = invert ? map(attVal, stats.max, stats.min, 1.0, 10.0) 
        : map(attVal, stats.min, stats.max, 1.0, 10.0);
      ((SimplePointMarker) m).setRadius(rad);
    } 
    this.setMarkers(temp);
    
    return stats;
  }
  
  public void printProperty(String s, boolean isString) {
    List<Marker> temp = this.getMarkers();
    
    for (Marker m : temp) {
    if (!isString) {
      println(m.getProperty(s));
      } else {
        println(m.getStringProperty(s));
      }
    } 
  }
  
  //takes care of mouse over and returns properties for marker if marker found
  public Marker checkMouseOver(float x, float y) {
    //performance issues on highlighting on passover
    this.setAllStrokeWeight(1);
    Marker m = this.getFirstHitMarker(x,y);  //look for fist marker
    if (m != null) {                         //if marker found
      m.setStrokeWeight(3);                  //set stroke to 3
      return m;                              // return marker for data
    }
    return null;
  }
  
  /* checls if a marker has been clicked, selects marker and returns this marker */
  public Marker checkClick(float x, float y) {
    List<Marker> temp = this.getMarkers();
      
    for (Marker m : temp) {
      if (m.isInside(map, x, y)) {
        if (m.isSelected()) {
          m.setSelected(false);
        } else {
          m.setSelected(true);
          return m;
        }
      }
    }
  this.setMarkers(temp);
  return null;
  }
  
  /* return all markers flagged selected */
  public List<Marker> getSelected() {
    List<Marker> temp = this.getMarkers();
    List<Marker> selected = new ArrayList<Marker>();
    
    for (Marker m : temp) {
        if (m.isSelected()) {
          selected.add(m);
        }
    }
    return selected;
  }
  
  /* deselect all markers */
  public void deselectAll() {
    List<Marker> temp = this.getMarkers();
    
    for (Marker m : temp) {
      m.setSelected(false);
    }
  this.setMarkers(temp);
  }
  
  //get and set the draw level
  public void setDrawLevel(int x) { this.drawLevel = x; }
  public int getDrawLevel() { return this.drawLevel; }
}
