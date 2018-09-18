// helper tools class
// Michael Holmes, September 2018
// student number: 928428

class Tools {
  public Tools() {}
   
  /* returns SumStats class data struct from a list of markers */
  public SumStats getSummaryStats(List<Marker> l, String a) {
    /* first get maximum value from attribute */
     SumStats s = new SumStats();                         // stats object to return
     float[] ar = new float[l.size()];                    // array for sample
    
    s.min = s.max = 0;   
    //add values to array
    for (int i = 0; i < l.size(); i++) {
      Object o = l.get(i).getProperty(a);
      ar[i] = Float.parseFloat(o.toString());
    }
    
    //get max
    for (int i = 0; i < ar.length; i++) {
      if (ar[i] > s.max) {
        s.max = ar[i];
      }
    }
    
    s.min = s.max;  //set min to max
    
    /* then get minimum value */
    for (int i = 0; i < ar.length; i++) {
      if (ar[i] < s.min) {
        s.min = ar[i];
      }
    }
    
    /* calculate average */
    for (int i = 0; i < ar.length; i++) {
      s.mean += ar[i];
    }
    s.mean = s.mean / ar.length;
    
    return s;
  }
  
  /* extracts data from a marker to an LGA data struct */
  public LGAData markerToLGAData(Marker m) {
    LGAData d = new LGAData();
    
    d.name = m.getStringProperty("LGA_NAME11");
    d.numSchools = Float.parseFloat(m.getProperty("NumSchools").toString());
    d.popPerSchool = Float.parseFloat(m.getProperty("pop_school_num_ratio").toString());
    d.IEOScore = Float.parseFloat(m.getProperty("edem_Score").toString());
    d.IRSADScore = Float.parseFloat(m.getProperty("ad_Score").toString());
    d.IERScore = Float.parseFloat(m.getProperty("ec_Score").toString());
    d.pop = Float.parseFloat(m.getProperty("ad_Usual Resident Population").toString());
    return d;
  }  
}
