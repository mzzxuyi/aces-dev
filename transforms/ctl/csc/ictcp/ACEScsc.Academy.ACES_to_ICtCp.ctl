
// <ACEStransformID>ACEScsc.ACES_to_ICtCp.a1.v1</ACEStransformID>
// <ACESuserName>ACES2065-1 to ICtCp</ACESuserName>

//
// ACES Color Space Conversion - ACES to ICtCp
//
// converts ACES2065-1 (AP0 w/ linear encoding) to 
//          ICtCp
//




// The AP0_2_LMS_MAT is a combination of the following individual matrices:
//   AP0_2_XYZ     : standard ACES to XYZ(D60) conversion matrix
//   D60_2_D65_CAT : XYZ(D60) to XYZ(D65) chromatic adaptation (using CAT02)
//   XYZ_2_LMS     : Hunt-Pointer-Estevez (normalized to D65) cone primary 
//                   matrix, using values from the Dolby ICtCp white paper:
//                              | 0.4002 0.7076 -0.0808 |
//                              |-0.2263 1.1653  0.0457 |
//                              | 0      0       0.9182 |
//   CROSSTALK     : the 4% crosstalk matrix described in the Dolby ICtCp white
//                   paper
const float AP0_2_LMS_MAT[3][3] = {
  { 0.5729360781,  0.1916984459,  0.0324676922},
  { 0.5052187675,  0.8013733145,  0.0551294631},
  {-0.0781710859,  0.0069006377,  0.9123015294}
};


const float LMSp_2_ICtCp_MAT[3][3] = {
  { 0.5,  1.6137000085,  4.3780624470},
  { 0.5, -3.3233961429, -4.2455397991},
  { 0.0,  1.7096961344, -0.1325226479}
};


// Constants from SMPTE ST 2084-2014
const float pq_m1 = 0.1593017578125; // ( 2610.0 / 4096.0 ) / 4.0;
const float pq_m2 = 78.84375; // ( 2523.0 / 4096.0 ) * 128.0;
const float pq_c1 = 0.8359375; // 3424.0 / 4096.0 or pq_c3 - pq_c2 + 1.0;
const float pq_c2 = 18.8515625; // ( 2413.0 / 4096.0 ) * 32.0;
const float pq_c3 = 18.6875; // ( 2392.0 / 4096.0 ) * 32.0;

const float pq_C = 10000.0;

// Converts from linear cd/m^2 to the non-linear perceptually quantized space
// Note that this is in float, and assumes normalization from 0 - 1
// (0 - pq_C for linear) and does not handle the integer coding in the Annex 
// sections of SMPTE ST 2084-2014
float Y_2_ST2084( float C )
//pq_r
{
  // Note that this does NOT handle any of the signal range
  // considerations from 2084 - this returns full range (0 - 1)
  float L = C / pq_C;
  float Lm = pow( L, pq_m1 );
  float N = ( pq_c1 + pq_c2 * Lm ) / ( 1.0 + pq_c3 * Lm );
  N = pow( N, pq_m2 );
  return N;
}

// Scale factor equal to PQ_rev( lin_2_acescct( 0.18) ) / 0.18
const float scale = 209.;



void main
(   
    input varying float rIn,
    input varying float gIn,
    input varying float bIn,
    input varying float aIn,
    output varying float rOut,
    output varying float gOut,
    output varying float bOut,
    output varying float aOut
)
{
    float ACES[3] = { rIn, gIn, bIn};
    
    // Apply scale factor
    ACES = mult_f_f3( scale, ACES);

    // Calculate LMS
    float LMS[3] = mult_f3_f33( ACES, AP0_2_LMS_MAT);

    // Apply ST 2084 non-linearity
    float LMSp[3];
    LMSp[0] = Y_2_ST2084( LMS[0]);
    LMSp[1] = Y_2_ST2084( LMS[1]);
    LMSp[2] = Y_2_ST2084( LMS[2]);

    // Calculate ICtCp
    float ICtCp[3] = mult_f3_f33( LMSp, LMSp_2_ICtCp_MAT);
    
    rOut = ICtCp[0];
    gOut = ICtCp[1];
    bOut = ICtCp[2];
    aOut = aIn;
}