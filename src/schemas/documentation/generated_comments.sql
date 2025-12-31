-- Generated schema documentation comments
-- Created by schema_documenter tool

-- Table: raw_domestic_epc_certificates_tbl
COMMENT ON TABLE mca_env_base.raw_domestic_epc_certificates_tbl IS 'Domestic Energy Performance Certificate data from UK government register';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LMK_KEY IS 'Individual lodgement identifier. Guaranteed to be unique and can be used to identify a certificate in the downloads and the API.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ADDRESS1 IS 'First line of the address';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ADDRESS2 IS 'Second line of the address';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ADDRESS3 IS 'Third line of the address';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.POSTCODE IS 'The postcode of the property';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.BUILDING_REFERENCE_NUMBER IS 'Unique identifier for the property.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CURRENT_ENERGY_RATING IS 'Current energy rating converted into a linear ''A to G'' rating (where A is the most energy efficient and G is the least energy efficient)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.POTENTIAL_ENERGY_RATING IS 'Estimated potential energy rating converted into a linear ''A to G'' rating (where A is the most energy efficient and G is the least energy efficient)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CURRENT_ENERGY_EFFICIENCY IS 'Based on cost of energy, i.e. energy required for space heating, water heating and lighting [in kWh/year] multiplied by fuel costs. (£/m²/year where cost is derived from kWh).';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.POTENTIAL_ENERGY_EFFICIENCY IS 'The potential energy efficiency rating of the property.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.PROPERTY_TYPE IS 'Describes the type of property such as House, Flat, Maisonette etc. This is the type differentiator for dwellings.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.BUILT_FORM IS 'The building type of the Property e.g. Detached, Semi-Detached, Terrace etc. Together with the Property Type, the Build Form produces a structured description of the property';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.INSPECTION_DATE IS 'The date that the inspection was actually carried out by the energy assessor';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LOCAL_AUTHORITY IS 'Office for National Statistics (ONS) code. Local authority area in which the building is located.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CONSTITUENCY IS 'Office for National Statistics (ONS) code. Parliamentary constituency in which the building is located.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.COUNTY IS 'County in which the building is located (where applicable)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LODGEMENT_DATE IS 'Date lodged on the Energy Performance of Buildings Register';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.TRANSACTION_TYPE IS 'Type of transaction that triggered EPC. For example, one of: marketed sale; non-marketed sale; new-dwelling; rental; not sale or rental; assessment for Green Deal; following Green Deal; FIT application; none of the above; RHI application; ECO assessment. Where the reason for the assessment is unknown by the energy assessor the transaction type will be recorded as ''none of the above''. Transaction types may be changed over time.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ENVIRONMENTAL_IMPACT_CURRENT IS 'The Environmental Impact Rating. A measure of the property''s current impact on the environment in terms of carbon dioxide (CO₂) emissions. The higher the rating the lower the CO₂ emissions. (CO₂ emissions in tonnes / year)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ENVIRONMENTAL_IMPACT_POTENTIAL IS 'The potential Environmental Impact Rating. A measure of the property''s potential impact on the environment in terms of carbon dioxide (CO₂) emissions after improvements have been carried out. The higher the rating the lower the CO₂ emissions. (CO₂ emissions in tonnes / year)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ENERGY_CONSUMPTION_CURRENT IS 'Current estimated total energy consumption for the property in a 12 month period (kWh/m2). Displayed on EPC as the current primary energy use per square metre of floor area.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ENERGY_CONSUMPTION_POTENTIAL IS 'Estimated potential total energy consumption for the Property in a 12 month period. Value is Kilowatt Hours per Square Metre (kWh/m²)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CO2_EMISSIONS_CURRENT IS 'CO₂ emissions per year in tonnes/year.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CO2_EMISS_CURR_PER_FLOOR_AREA IS 'CO₂ emissions per square metre floor area per year in kg/m²';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CO2_EMISSIONS_POTENTIAL IS 'Estimated value in Tonnes per Year of the total CO₂ emissions produced by the Property in 12 month period.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LIGHTING_COST_CURRENT IS 'GBP. Current estimated annual energy costs for lighting the property.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LIGHTING_COST_POTENTIAL IS 'GBP. Potential estimated annual energy costs for lighting the property after improvements have been made.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HEATING_COST_CURRENT IS 'GBP. Current estimated annual energy costs for heating the property.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HEATING_COST_POTENTIAL IS 'GBP. Potential annual energy costs for lighting the property after improvements have been made.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HOT_WATER_COST_CURRENT IS 'GBP. Current estimated annual energy costs for hot water';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HOT_WATER_COST_POTENTIAL IS 'GBP. Potential estimated annual energy costs for hot water after improvements have been made.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.TOTAL_FLOOR_AREA IS 'The total useful floor area is the total of all enclosed spaces measured to the internal face of the external walls, i.e. the gross floor area as measured in accordance with the guidance issued from time to time by the Royal Institute of Chartered Surveyors or by a body replacing that institution. (m²)';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ENERGY_TARIFF IS 'Type of electricity tariff for the property, e.g. single.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINS_GAS_FLAG IS 'Whether mains gas is available. Yes means that there is a gas meter or a gas-burning appliance in the dwelling. A closed-off gas pipe does not count.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLOOR_LEVEL IS 'Flats and maisonettes only. Floor level relative to the lowest level of the property (0 for ground floor). If there is a basement, the basement is level 0 and the other floors are from 1 upwards';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLAT_TOP_STOREY IS 'Whether the flat is on the top storey';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLAT_STOREY_COUNT IS 'The number of storeys in the apartment block.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAIN_HEATING_CONTROLS IS 'Type of main heating controls. Includes both main heating systems if there are two.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MULTI_GLAZE_PROPORTION IS 'The estimated banded range (e.g. 0% - 10%) of the total glazed area of the Property that is multiple glazed.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.GLAZED_TYPE IS 'The type of glazing. From British Fenestration Rating Council or manufacturer declaration, one of; single; double; triple.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.GLAZED_AREA IS 'Ranged estimate of the total glazed area of the Habitable Area.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.EXTENSION_COUNT IS 'The number of extensions added to the property. Between 0 and 4.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.NUMBER_HABITABLE_ROOMS IS 'Habitable rooms include any living room, sitting room, dining room, bedroom, study and similar; and also a non-separated conservatory. A kitchen/diner having a discrete seating area (with space for a table and four chairs) also counts as a habitable room. A non-separated conservatory adds to the habitable room count if it has an internal quality door between it and the dwelling. Excluded from the room count are any room used solely as a kitchen, utility room, bathroom, cloakroom, en-suite accommodation and similar and any hallway, stairs or landing; and also any room not having a window.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.NUMBER_HEATED_ROOMS IS 'The number of heated rooms in the property if more than half of the habitable rooms are not heated.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LOW_ENERGY_LIGHTING IS 'The percentage of low energy lighting present in the property as a percentage of the total fixed lights in the property. 0% indicates that no low-energy lighting is present.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.NUMBER_OPEN_FIREPLACES IS 'The number of Open Fireplaces in the Property. An Open Fireplace is a fireplace that still allows air to pass between the inside of the Property and the outside.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HOTWATER_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HOT_WATER_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HOT_WATER_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLOOR_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLOOR_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLOOR_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WINDOWS_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WINDOWS_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WINDOWS_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WALLS_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WALLS_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WALLS_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.SECONDHEAT_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.SHEATING_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.SHEATING_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ROOF_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ROOF_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ROOF_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINHEAT_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINHEAT_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINHEAT_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINHEATCONT_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINHEATC_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAINHEATC_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LIGHTING_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LIGHTING_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LIGHTING_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MAIN_FUEL IS 'The type of fuel used to power the central heating e.g. Gas, Electricity';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.WIND_TURBINE_COUNT IS 'Number of wind turbines; 0 if none.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.HEAT_LOSS_CORRIDOR IS 'Flats and maisonettes only. Indicates that the flat contains a corridor through which heat is lost. Heat loss corridor, one of: no corridor; heated corridor; unheated corridor';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.UNHEATED_CORRIDOR_LENGTH IS 'The total length of unheated corridor in the flat. Only populated if flat or maisonette contains unheated corridor. If unheated corridor, length of sheltered wall (m²).';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FLOOR_HEIGHT IS 'Average height of the storey in metres.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.PHOTO_SUPPLY IS 'Percentage of photovoltaic area as a percentage of total roof area. 0% indicates that a Photovoltaic Supply is not present in the property.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.SOLAR_WATER_HEATING_FLAG IS 'Indicates whether the heating in the Property is solar powered.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.MECHANICAL_VENTILATION IS 'Identifies the type of mechanical ventilation the property has. This is required for the RdSAP calculation.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.ADDRESS IS 'Field containing the concatenation of address1, address2 and address3. Note that post code is recorded separately.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LOCAL_AUTHORITY_LABEL IS 'The name of the local authority area in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Local Authority ONS Code.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CONSTITUENCY_LABEL IS 'The name of the parliamentary constituency in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Constituency ONS Code.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.POSTTOWN IS 'The post town of the property';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.CONSTRUCTION_AGE_BAND IS 'Age band when building part constructed. England & Wales only. One of: before 1900; 1900-1929; 1930-1949; 1950-1966; 1967-1975; 1976-1982; 1983-1990; 1991-1995; 1996-2002; 2003-2006; 2007-2011; 2012 onwards.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LODGEMENT_DATETIME IS 'Date and time lodged on the Energy Performance of Buildings Register.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.TENURE IS 'Describes the tenure type of the property. One of: Owner-occupied; Rented (social); Rented (private).';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.FIXED_LIGHTING_OUTLETS_COUNT IS 'The number of fixed lighting outlets.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.LOW_ENERGY_FIXED_LIGHT_COUNT IS 'The number of low-energy fixed lighting outlets.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.UPRN IS 'The UPRN submitted by an assessor or alternatively from the department’s address matching algorithm.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.UPRN_SOURCE IS 'Populated with the values "Energy Assessor" or "Address Matched" to show how the UPRN was populated.';
COMMENT ON COLUMN mca_env_base.raw_domestic_epc_certificates_tbl.REPORT_TYPE IS 'Type of assessment carried out on the building, for domestic dwellings this is either a SAP (Standard Assessment Procedure) or a Reduced SAP. 100: RdSAP (Reduced SAP for existing buildings) and 101: SAP (full Sap for new dwellings, including conversions and change of use). This variable will help distinguish between new and existing dwellings.';

-- Table: raw_non_domestic_epc_certificates_tbl
COMMENT ON TABLE mca_env_base.raw_non_domestic_epc_certificates_tbl IS 'Non-domestic Energy Performance Certificate data from UK government register';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.LMK_KEY IS 'Individual lodgement identifier. Guaranteed to be unique and can be used to identify a certificate in the downloads and the API.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ADDRESS1 IS 'First line of the address';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ADDRESS2 IS 'Second line of the address';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ADDRESS3 IS 'Third line of the address';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.POSTCODE IS 'The postcode of the property';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.BUILDING_REFERENCE_NUMBER IS 'Unique identifier for the property.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ASSET_RATING IS 'Energy Performance Asset Rating. The CO₂ emissions from the actual building in comparison to a Standard Emission Rate. (kg CO₂/m²)';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ASSET_RATING_BAND IS 'Energy Performance Asset Rating converted into an energy band/grade into a linear ''A+ to G'' scale (where A+ is the most energy efficient and G the least energy efficient)';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.PROPERTY_TYPE IS 'Describes the type of building that is being inspected. Based on planning use class.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.INSPECTION_DATE IS 'The date that the inspection was actually carried out by the energy assessor';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.LOCAL_AUTHORITY IS 'Office for National Statistics (ONS) code. Local authority area in which the building is located.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.CONSTITUENCY IS 'Office for National Statistics (ONS) code. Parliamentary constituency in which the building is located.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.COUNTY IS 'County in which the building is located (where applicable)';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.LODGEMENT_DATE IS 'Date lodged on the Energy Performance of Buildings Register';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.TRANSACTION_TYPE IS 'Type of transaction that triggered EPC. One of: mandatory issue (marketed sale); mandatory issue (non-marketed sale); mandatory issue (property on construction); mandatory issue (property to let); voluntary re-issue (a valid epc is already lodged); voluntary (no legal requirement for an epc); not recorded. Transaction types may be changed over time.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.NEW_BUILD_BENCHMARK IS 'NEW_BUILD_BENCHMARK';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.EXISTING_STOCK_BENCHMARK IS 'The Benchmark value of existing stock for this type of building';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.BUILDING_LEVEL IS 'Building Complexity Level based on Energy Assessor National Occupation Standards';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.MAIN_HEATING_FUEL IS 'Main Heating fuel for the building is taken as the fuel which delivers the greatest total thermal output for space or water heating';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.OTHER_FUEL_DESC IS 'Text description of unspecified fuel type if ''Other'' is selected for Main Heating Fuel';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.SPECIAL_ENERGY_USES IS 'Special energy uses discounted. This only appears on the Recommendations Report.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.RENEWABLE_SOURCES IS 'On-site renewable energy sources. This only appears on the Advisory Report.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.FLOOR_AREA IS 'The total useful floor area is the total of all enclosed spaces measured to the internal face of the external walls, i.e. the gross floor area as measured in accordance with the guidance issued from time to time by the Royal Institute of Chartered Surveyors or by a body replacing that institution. (m2)';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.STANDARD_EMISSIONS IS 'Standard Emission Rate is determined by applying a fixed improvement factor to the emissions from a reference building. (kg CO₂/m²/year).';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.TARGET_EMISSIONS IS 'Standard Emission Rate is determined by applying a fixed improvement factor to the emissions from a reference building. (kg CO₂/m²/year).';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.TYPICAL_EMISSIONS IS 'Typical Emission Rate.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.BUILDING_EMISSIONS IS 'Building Emissions Rate. Annual CO₂ emissions from the building. Decimal (kg CO₂/m²)';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.AIRCON_PRESENT IS 'Air Conditioning System. Does the building have an air conditioning system?';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.AIRCON_KW_RATING IS 'Air conditioning System. Rating in kW';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ESTIMATED_AIRCON_KW_RATING IS 'Air Conditioning System. If exact rating unknown, what is the estimated total effective output rating of the air conditioning system';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.AC_INSPECTION_COMMISSIONED IS 'One of:1=Yes, inspection completed; 2=Yes, inspection commissioned; 3=No inspection completed or commissioned; 4=Not relevant; 5=Don''t know';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.BUILDING_ENVIRONMENT IS 'Building environment which is taken as the servicing strategy that contributes the largest proportion of the building''s CO₂ emissions.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.ADDRESS IS 'Field containing the concatenation of address1, address2 and address3. Note that post code is recorded separately.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.LOCAL_AUTHORITY_LABEL IS 'The name of the local authority area in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Local Authority ONS Code.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.CONSTITUENCY_LABEL IS 'The name of the parliamentary constituency in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Constituency ONS Code.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.POSTTOWN IS 'The post town of the property';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.LODGEMENT_DATETIME IS 'Date and time lodged on the Energy Performance of Buildings Register.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.PRIMARY_ENERGY_VALUE IS 'Displayed on the non-domestic EPC as primary energy use (kWh/m2 per year)';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.UPRN IS 'The UPRN submitted by an assessor or alternatively from the department’s address matching algorithm.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.UPRN_SOURCE IS 'Populated with the values "Energy Assessor" or "Address Matched" to show how the UPRN was populated.';
COMMENT ON COLUMN mca_env_base.raw_non_domestic_epc_certificates_tbl.REPORT_TYPE IS 'Type of assessment carried out of the building. 102: assessment using the SBEM (Simplified Building Energy Model) tool for non-domestic (non-residential) buildings.';

-- Table: bdline_ua_lep_diss_tbl
COMMENT ON TABLE mca_env_base.bdline_ua_lep_diss_tbl IS 'Table containing 3 columns';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_diss_tbl.name IS 'Name';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_diss_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_diss_tbl.id IS 'Id';

-- Table: bdline_ua_lep_tbl
COMMENT ON TABLE mca_env_base.bdline_ua_lep_tbl IS 'Table containing 4 columns';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_tbl.name IS 'Name';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_tbl.code IS 'Code';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.bdline_ua_lep_tbl.id IS 'Id';

-- Table: bdline_ua_weca_diss_tbl
COMMENT ON TABLE mca_env_base.bdline_ua_weca_diss_tbl IS 'Table containing 3 columns';
COMMENT ON COLUMN mca_env_base.bdline_ua_weca_diss_tbl.name IS 'Name';
COMMENT ON COLUMN mca_env_base.bdline_ua_weca_diss_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.bdline_ua_weca_diss_tbl.id IS 'Id';

-- Table: bdline_ward_lep_tbl
COMMENT ON TABLE mca_env_base.bdline_ward_lep_tbl IS 'Table containing 5 columns';
COMMENT ON COLUMN mca_env_base.bdline_ward_lep_tbl.name IS 'Name';
COMMENT ON COLUMN mca_env_base.bdline_ward_lep_tbl.file_name IS 'File name';
COMMENT ON COLUMN mca_env_base.bdline_ward_lep_tbl.code IS 'Code';
COMMENT ON COLUMN mca_env_base.bdline_ward_lep_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.bdline_ward_lep_tbl.id IS 'Id';

-- Table: boundary_lookup_tbl
COMMENT ON TABLE mca_env_base.boundary_lookup_tbl IS 'Table containing 14 columns';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.pcd7 IS 'Pcd7';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.pcd8 IS 'Pcd8';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.pcds IS 'Pcds';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.dointr IS 'Dointr';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.doterm IS 'Doterm';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.usertype IS 'Usertype';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.oa21cd IS 'Oa21cd';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.lsoa21cd IS 'Lsoa21cd';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.msoa21cd IS 'Msoa21cd';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.ladcd IS 'Local Authority District code';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.lsoa21nm IS 'Lsoa21nm';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.msoa21nm IS 'Msoa21nm';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.ladnm IS 'Local Authority District name';
COMMENT ON COLUMN mca_env_base.boundary_lookup_tbl.ladnmw IS 'Ladnmw';

-- Table: ca_boundaries_bgc_tbl
COMMENT ON TABLE mca_env_base.ca_boundaries_bgc_tbl IS 'Table containing 11 columns';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.FID IS 'Fid';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.CAUTH25CD IS 'Cauth25cd';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.CAUTH25NM IS 'Cauth25nm';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.BNG_E IS 'Bng e';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.BNG_N IS 'Bng n';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.LONG IS 'Long';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.LAT IS 'Lat';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.Shape__Area IS 'Shape area';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.Shape__Length IS 'Shape length';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.GlobalID IS 'Globalid';
COMMENT ON COLUMN mca_env_base.ca_boundaries_bgc_tbl.geom IS 'Geometry';

-- Table: ca_la_lookup_tbl
COMMENT ON TABLE mca_env_base.ca_la_lookup_tbl IS 'Table containing 5 columns';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_tbl.LAD25CD IS 'Lad25cd';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_tbl.LAD25NM IS 'Lad25nm';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_tbl.CAUTH25CD IS 'Cauth25cd';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_tbl.CAUTH25NM IS 'Cauth25nm';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_tbl.ObjectId IS 'Objectid';

-- Table: codepoint_open_lep_tbl
COMMENT ON TABLE mca_env_base.codepoint_open_lep_tbl IS 'Table containing 10 columns';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.postcode IS 'UK postal code';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.pc_nospace IS 'Pc nospace';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.admin_district_code IS 'Admin district code';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.admin_ward_code IS 'Admin ward code';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.xco IS 'Xco';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.yco IS 'Yco';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.lon IS 'Lon';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.lat IS 'Lat';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.codepoint_open_lep_tbl.id IS 'Id';

-- Table: eng_lsoa_imd_tbl
COMMENT ON TABLE mca_env_base.eng_lsoa_imd_tbl IS 'Table containing 25 columns';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.lsoa21_code IS 'Lsoa21 code';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.imd_decile IS 'Imd decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.income_decile IS 'Income decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.employment_decile IS 'Employment decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.education_decile IS 'Education decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.health_decile IS 'Health decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.crime_decile IS 'Crime decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.housing_and_services_decile IS 'Housing and services decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.environment_decile IS 'Environment decile';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.imd_rank IS 'Imd rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.income_rank IS 'Income rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.employment_rank IS 'Employment rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.education_rank IS 'Education rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.health_rank IS 'Health rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.crime_rank IS 'Crime rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.housing_and_services_rank IS 'Housing and services rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.environment_rank IS 'Environment rank';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.imd_score IS 'Imd score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.income_score IS 'Income score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.employment_score IS 'Employment score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.education_score IS 'Education score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.health_score IS 'Health score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.crime_score IS 'Crime score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.housing_and_services_score IS 'Housing and services score';
COMMENT ON COLUMN mca_env_base.eng_lsoa_imd_tbl.environment_score IS 'Environment score';

-- Table: la_ghg_emissions_tbl
COMMENT ON TABLE mca_env_base.la_ghg_emissions_tbl IS 'Table containing 15 columns';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.country IS 'Country';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.country_code IS 'Country code';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.region IS 'Region';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.region_code IS 'Region code';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.second_tier_authority IS 'Second tier authority';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.local_authority IS 'Local authority';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.local_authority_code IS 'Local authority code';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.calendar_year IS 'Calendar year';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.la_ghg_sector IS 'La ghg sector';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.la_ghg_subsector IS 'La ghg subsector';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.greenhouse_gas IS 'Greenhouse gas';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.territorial_emissions_kt_co2e IS 'Territorial emissions kt co2e';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.emissions_within_the_scope_of_influence_of_las_kt_co2 IS 'Emissions within the scope of influence of las kt co2';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.midyear_population_thousands IS 'Midyear population thousands';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_tbl.area_km2 IS 'Area km2';

-- Table: la_ghg_emissions_wide_tbl
COMMENT ON TABLE mca_env_base.la_ghg_emissions_wide_tbl IS 'Table containing 50 columns';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.regioncountry IS 'Regioncountry';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.second_tier_authority IS 'Second tier authority';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.local_authority IS 'Local authority';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.local_authority_code IS 'Local authority code';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.calendar_year IS 'Calendar year';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.industry_electricity IS 'Industry electricity';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.industry_gas IS 'Industry gas';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.large_industrial_installations IS 'Large industrial installations';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.industry_other IS 'Industry other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.industry_total IS 'Industry total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.commercial_electricity IS 'Commercial electricity';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.commercial_gas IS 'Commercial gas';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.commercial_other IS 'Commercial other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.commercial_total IS 'Commercial total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.public_sector_electricity IS 'Public sector electricity';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.public_sector_gas IS 'Public sector gas';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.public_sector_other IS 'Public sector other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.public_sector_total IS 'Public sector total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.domestic_electricity IS 'Domestic electricity';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.domestic_gas IS 'Domestic gas';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.domestic_other IS 'Domestic other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.domestic_total IS 'Domestic total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.road_transport_a_roads IS 'Road transport a roads';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.road_transport_motorways IS 'Road transport motorways';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.road_transport_minor_roads IS 'Road transport minor roads';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.diesel_railways IS 'Diesel railways';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.transport_other IS 'Transport other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.transport_total IS 'Transport total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_forestry IS 'Net emissions forestry';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_cropland_mineral_soils_change IS 'Net emissions cropland mineral soils change';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_grassland_mineral_soils_change IS 'Net emissions grassland mineral soils change';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_settlements IS 'Net emissions settlements';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_peatland IS 'Net emissions peatland';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_bioenergy_crops IS 'Net emissions bioenergy crops';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.net_emissions_other_lulucf IS 'Net emissions other lulucf';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.lulucf_net_emissions IS 'Lulucf net emissions';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.agriculture_electricity IS 'Agriculture electricity';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.agriculture_gas IS 'Agriculture gas';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.agriculture_other IS 'Agriculture other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.agriculture_livestock IS 'Agriculture livestock';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.agriculture_soils IS 'Agriculture soils';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.agriculture_total IS 'Agriculture total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.landfill IS 'Landfill';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.waste_other IS 'Waste other';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.waste_total IS 'Waste total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.grand_total IS 'Grand total';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.population_000s_midyear_estimate IS 'Population 000s midyear estimate';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.per_capita_emissions_t_co2e IS 'Per capita emissions t co2e';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.area_km2 IS 'Area km2';
COMMENT ON COLUMN mca_env_base.la_ghg_emissions_wide_tbl.emissions_per_km2_kt_co2e IS 'Emissions per km2 kt co2e';

-- Table: lsoa_2021_lep_tbl
COMMENT ON TABLE mca_env_base.lsoa_2021_lep_tbl IS 'Table containing 5 columns';
COMMENT ON COLUMN mca_env_base.lsoa_2021_lep_tbl.lsoa21cd IS 'Lsoa21cd';
COMMENT ON COLUMN mca_env_base.lsoa_2021_lep_tbl.lsoa21nm IS 'Lsoa21nm';
COMMENT ON COLUMN mca_env_base.lsoa_2021_lep_tbl.area_m2 IS 'Area m2';
COMMENT ON COLUMN mca_env_base.lsoa_2021_lep_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.lsoa_2021_lep_tbl.id IS 'Id';

-- Table: open_uprn_lep_tbl
COMMENT ON TABLE mca_env_base.open_uprn_lep_tbl IS 'Table containing 5 columns';
COMMENT ON COLUMN mca_env_base.open_uprn_lep_tbl.uprn IS 'Unique Property Reference Number';
COMMENT ON COLUMN mca_env_base.open_uprn_lep_tbl.x_coordinate IS 'X coordinate';
COMMENT ON COLUMN mca_env_base.open_uprn_lep_tbl.y_coordinate IS 'Y coordinate';
COMMENT ON COLUMN mca_env_base.open_uprn_lep_tbl.shape IS 'Spatial geometry';
COMMENT ON COLUMN mca_env_base.open_uprn_lep_tbl.id IS 'Id';

-- Table: postcode_centroids_tbl
COMMENT ON TABLE mca_env_base.postcode_centroids_tbl IS 'Table containing 60 columns';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.x IS 'X';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.y IS 'Y';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.objectid IS 'Objectid';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.pcd7 IS 'Pcd7';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.pcd8 IS 'Pcd8';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.pcds IS 'Pcds';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.dointr IS 'Dointr';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.doterm IS 'Doterm';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.cty25cd IS 'Cty25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ced25cd IS 'Ced25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lad25cd IS 'Lad25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.wd25cd IS 'Wd25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.parncp25cd IS 'Parncp25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.usrtypind IS 'Usrtypind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.east1m IS 'East1m';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.north1m IS 'North1m';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.gridind IS 'Gridind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.hlth19cd IS 'Hlth19cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.nhser24cd IS 'Nhser24cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ctry25cd IS 'Ctry25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.rgn25cd IS 'Rgn25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ssr95cd IS 'Ssr95cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.pcon24cd IS 'Pcon24cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.eer20cd IS 'Eer20cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.educ23cd IS 'Educ23cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ttwa15cd IS 'Ttwa15cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.pco19cd IS 'Pco19cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.itl25cd IS 'Itl25cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.wdstl05cd IS 'Wdstl05cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.oa01cd IS 'Oa01cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.wdcas03cd IS 'Wdcas03cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.npark16cd IS 'Npark16cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lsoa01cd IS 'Lsoa01cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.msoa01cd IS 'Msoa01cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ruc01ind IS 'Ruc01ind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.oac01ind IS 'Oac01ind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.oa11cd IS 'Oa11cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lsoa11cd IS 'Lsoa11cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.msoa11cd IS 'Msoa11cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.wz11cd IS 'Wz11cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.sicbl24cd IS 'Sicbl24cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.bua24cd IS 'Bua24cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ruc11ind IS 'Ruc11ind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.oac11ind IS 'Oac11ind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lat IS 'Lat';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.long IS 'Long';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lep21cd1 IS 'Lep21cd1';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lep21cd2 IS 'Lep21cd2';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.pfa23cd IS 'Pfa23cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.imd20ind IS 'Imd20ind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.cal24cd IS 'Cal24cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.icb23cd IS 'Icb23cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.oa21cd IS 'Oa21cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.lsoa21cd IS 'Lsoa21cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.msoa21cd IS 'Msoa21cd';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.ruc21ind IS 'Ruc21ind';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.f_matched_characters IS 'F matched characters';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.f_matched_parts___part IS 'F matched parts part';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.f_matched_parts___startindex IS 'F matched parts startindex';
COMMENT ON COLUMN mca_env_base.postcode_centroids_tbl.globalid IS 'Globalid';

-- Table: uk_lsoa_tenure_tbl
COMMENT ON TABLE mca_env_base.uk_lsoa_tenure_tbl IS 'Table containing 5 columns';
COMMENT ON COLUMN mca_env_base.uk_lsoa_tenure_tbl.lsoa21_code IS 'Lsoa21 code';
COMMENT ON COLUMN mca_env_base.uk_lsoa_tenure_tbl.total_households IS 'Total households';
COMMENT ON COLUMN mca_env_base.uk_lsoa_tenure_tbl.tenure IS 'Tenure';
COMMENT ON COLUMN mca_env_base.uk_lsoa_tenure_tbl.n IS 'N';
COMMENT ON COLUMN mca_env_base.uk_lsoa_tenure_tbl.prop IS 'Prop';

-- Views

-- View: ca_boundaries_inc_ns_vw
COMMENT ON TABLE mca_env_base.ca_boundaries_inc_ns_vw IS 'View based on ca_boundaries_bgc_tbl, bdline_ua_lep_diss_tbl';
COMMENT ON COLUMN mca_env_base.ca_boundaries_inc_ns_vw.cauthcd IS 'Cauthcd';
COMMENT ON COLUMN mca_env_base.ca_boundaries_inc_ns_vw.cauthnm IS 'Cauthnm';
COMMENT ON COLUMN mca_env_base.ca_boundaries_inc_ns_vw.geom IS 'Geometry';

-- View: ca_la_ghg_emissions_sub_sector_ods_vw
COMMENT ON TABLE mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw IS 'View based on la_ghg_emissions_tbl, joined_data;, ca_la_lookup_inc_ns_vw';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.region_code IS 'Region code';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.local_authority IS 'Local authority';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.local_authority_code IS 'Local authority code';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.calendar_year IS 'Calendar year';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.la_ghg_sector IS 'La ghg sector';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.la_ghg_subsector IS 'La ghg subsector';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.greenhouse_gas IS 'Greenhouse gas';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.territorial_emissions_kt_co2e IS 'Territorial emissions kt co2e';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.emissions_within_the_scope_of_influence_of_las_kt_co2 IS 'Emissions within the scope of influence of las kt co2';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.midyear_population_thousands IS 'Midyear population thousands';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.area_km2 IS 'Area km2';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.cauthcd IS 'Cauthcd';
COMMENT ON COLUMN mca_env_base.ca_la_ghg_emissions_sub_sector_ods_vw.cauthnm IS 'Cauthnm';

-- View: ca_la_lookup_inc_ns_vw
COMMENT ON TABLE mca_env_base.ca_la_lookup_inc_ns_vw IS 'View based on ca_la_lookup_tbl';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.ladcd IS 'Ladcd';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.ladnm IS 'Ladnm';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.cauthcd IS 'Cauthcd';
COMMENT ON COLUMN mca_env_base.ca_la_lookup_inc_ns_vw.cauthnm IS 'Cauthnm';

-- View: character_sets
COMMENT ON TABLE mca_env_base.character_sets IS 'View: character_sets';
COMMENT ON COLUMN mca_env_base.character_sets.character_set_catalog IS 'Computed field: character_set_catalog';
COMMENT ON COLUMN mca_env_base.character_sets.character_set_schema IS 'Computed field: character_set_schema';
COMMENT ON COLUMN mca_env_base.character_sets.character_set_name IS 'Computed field: character_set_name';
COMMENT ON COLUMN mca_env_base.character_sets.character_repertoire IS 'Computed field: character_repertoire';
COMMENT ON COLUMN mca_env_base.character_sets.form_of_use IS 'Computed field: form_of_use';
COMMENT ON COLUMN mca_env_base.character_sets.default_collate_catalog IS 'Computed field: default_collate_catalog';
COMMENT ON COLUMN mca_env_base.character_sets.default_collate_schema IS 'Computed field: default_collate_schema';
COMMENT ON COLUMN mca_env_base.character_sets.default_collate_name IS 'Computed field: default_collate_name';

-- View: check_constraints
COMMENT ON TABLE mca_env_base.check_constraints IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.check_constraints.constraint_catalog IS 'Constraint catalog';
COMMENT ON COLUMN mca_env_base.check_constraints.constraint_schema IS 'Constraint schema';
COMMENT ON COLUMN mca_env_base.check_constraints.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.check_constraints.check_clause IS 'Computed field: check_clause';

-- View: columns
COMMENT ON TABLE mca_env_base.columns IS 'View based on duckdb_columns;';
COMMENT ON COLUMN mca_env_base.columns.table_catalog IS 'Table catalog';
COMMENT ON COLUMN mca_env_base.columns.table_schema IS 'Table schema';
COMMENT ON COLUMN mca_env_base.columns.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.columns.column_name IS 'Column name';
COMMENT ON COLUMN mca_env_base.columns.ordinal_position IS 'Ordinal position';
COMMENT ON COLUMN mca_env_base.columns.column_default IS 'Column default';
COMMENT ON COLUMN mca_env_base.columns.is_nullable IS 'Computed field: is_nullable';
COMMENT ON COLUMN mca_env_base.columns.data_type IS 'Data type';
COMMENT ON COLUMN mca_env_base.columns.character_maximum_length IS 'Character maximum length';
COMMENT ON COLUMN mca_env_base.columns.character_octet_length IS 'Computed field: character_octet_length';
COMMENT ON COLUMN mca_env_base.columns.numeric_precision IS 'Numeric precision';
COMMENT ON COLUMN mca_env_base.columns.numeric_precision_radix IS 'Numeric precision radix';
COMMENT ON COLUMN mca_env_base.columns.numeric_scale IS 'Numeric scale';
COMMENT ON COLUMN mca_env_base.columns.datetime_precision IS 'Computed field: datetime_precision';
COMMENT ON COLUMN mca_env_base.columns.interval_type IS 'Computed field: interval_type';
COMMENT ON COLUMN mca_env_base.columns.interval_precision IS 'Computed field: interval_precision';
COMMENT ON COLUMN mca_env_base.columns.character_set_catalog IS 'Computed field: character_set_catalog';
COMMENT ON COLUMN mca_env_base.columns.character_set_schema IS 'Computed field: character_set_schema';
COMMENT ON COLUMN mca_env_base.columns.character_set_name IS 'Computed field: character_set_name';
COMMENT ON COLUMN mca_env_base.columns.collation_catalog IS 'Computed field: collation_catalog';
COMMENT ON COLUMN mca_env_base.columns.collation_schema IS 'Computed field: collation_schema';
COMMENT ON COLUMN mca_env_base.columns.collation_name IS 'Computed field: collation_name';
COMMENT ON COLUMN mca_env_base.columns.domain_catalog IS 'Computed field: domain_catalog';
COMMENT ON COLUMN mca_env_base.columns.domain_schema IS 'Computed field: domain_schema';
COMMENT ON COLUMN mca_env_base.columns.domain_name IS 'Computed field: domain_name';
COMMENT ON COLUMN mca_env_base.columns.udt_catalog IS 'Computed field: udt_catalog';
COMMENT ON COLUMN mca_env_base.columns.udt_schema IS 'Computed field: udt_schema';
COMMENT ON COLUMN mca_env_base.columns.udt_name IS 'Computed field: udt_name';
COMMENT ON COLUMN mca_env_base.columns.scope_catalog IS 'Computed field: scope_catalog';
COMMENT ON COLUMN mca_env_base.columns.scope_schema IS 'Computed field: scope_schema';
COMMENT ON COLUMN mca_env_base.columns.scope_name IS 'Computed field: scope_name';
COMMENT ON COLUMN mca_env_base.columns.maximum_cardinality IS 'Computed field: maximum_cardinality';
COMMENT ON COLUMN mca_env_base.columns.dtd_identifier IS 'Computed field: dtd_identifier';
COMMENT ON COLUMN mca_env_base.columns.is_self_referencing IS 'Computed field: is_self_referencing';
COMMENT ON COLUMN mca_env_base.columns.is_identity IS 'Computed field: is_identity';
COMMENT ON COLUMN mca_env_base.columns.identity_generation IS 'Computed field: identity_generation';
COMMENT ON COLUMN mca_env_base.columns.identity_start IS 'Computed field: identity_start';
COMMENT ON COLUMN mca_env_base.columns.identity_increment IS 'Computed field: identity_increment';
COMMENT ON COLUMN mca_env_base.columns.identity_maximum IS 'Computed field: identity_maximum';
COMMENT ON COLUMN mca_env_base.columns.identity_minimum IS 'Computed field: identity_minimum';
COMMENT ON COLUMN mca_env_base.columns.identity_cycle IS 'Computed field: identity_cycle';
COMMENT ON COLUMN mca_env_base.columns.is_generated IS 'Computed field: is_generated';
COMMENT ON COLUMN mca_env_base.columns.generation_expression IS 'Computed field: generation_expression';
COMMENT ON COLUMN mca_env_base.columns.is_updatable IS 'Computed field: is_updatable';
COMMENT ON COLUMN mca_env_base.columns.COLUMN_COMMENT IS 'Computed field: COLUMN_COMMENT';

-- View: constraint_column_usage
COMMENT ON TABLE mca_env_base.constraint_column_usage IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.table_catalog IS 'Table catalog';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.table_schema IS 'Table schema';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.column_name IS 'Column name';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.constraint_catalog IS 'Constraint catalog';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.constraint_schema IS 'Constraint schema';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.constraint_type IS 'Constraint type';
COMMENT ON COLUMN mca_env_base.constraint_column_usage.constraint_text IS 'Constraint text';

-- View: constraint_table_usage
COMMENT ON TABLE mca_env_base.constraint_table_usage IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.table_catalog IS 'Table catalog';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.table_schema IS 'Table schema';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.constraint_catalog IS 'Constraint catalog';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.constraint_schema IS 'Constraint schema';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.constraint_table_usage.constraint_type IS 'Constraint type';

-- View: duckdb_columns
COMMENT ON TABLE mca_env_base.duckdb_columns IS 'View based on duckdb_columns';
COMMENT ON COLUMN mca_env_base.duckdb_columns.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_columns.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_columns.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_columns.schema_oid IS 'Schema oid';
COMMENT ON COLUMN mca_env_base.duckdb_columns.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.duckdb_columns.table_oid IS 'Table oid';
COMMENT ON COLUMN mca_env_base.duckdb_columns.column_name IS 'Column name';
COMMENT ON COLUMN mca_env_base.duckdb_columns.column_index IS 'Column index';
COMMENT ON COLUMN mca_env_base.duckdb_columns.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_columns.internal IS 'Internal';
COMMENT ON COLUMN mca_env_base.duckdb_columns.column_default IS 'Column default';
COMMENT ON COLUMN mca_env_base.duckdb_columns.is_nullable IS 'Is nullable';
COMMENT ON COLUMN mca_env_base.duckdb_columns.data_type IS 'Data type';
COMMENT ON COLUMN mca_env_base.duckdb_columns.data_type_id IS 'Data type id';
COMMENT ON COLUMN mca_env_base.duckdb_columns.character_maximum_length IS 'Character maximum length';
COMMENT ON COLUMN mca_env_base.duckdb_columns.numeric_precision IS 'Numeric precision';
COMMENT ON COLUMN mca_env_base.duckdb_columns.numeric_precision_radix IS 'Numeric precision radix';
COMMENT ON COLUMN mca_env_base.duckdb_columns.numeric_scale IS 'Numeric scale';

-- View: duckdb_constraints
COMMENT ON TABLE mca_env_base.duckdb_constraints IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.schema_oid IS 'Schema oid';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.table_oid IS 'Table oid';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.constraint_index IS 'Constraint index';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.constraint_type IS 'Constraint type';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.constraint_text IS 'Constraint text';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.expression IS 'Expression';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.constraint_column_indexes IS 'Constraint column indexes';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.constraint_column_names IS 'Constraint column names';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.referenced_table IS 'Referenced table';
COMMENT ON COLUMN mca_env_base.duckdb_constraints.referenced_column_names IS 'Referenced column names';

-- View: duckdb_databases
COMMENT ON TABLE mca_env_base.duckdb_databases IS 'View based on duckdb_databases';
COMMENT ON COLUMN mca_env_base.duckdb_databases.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_databases.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_databases.path IS 'Path';
COMMENT ON COLUMN mca_env_base.duckdb_databases.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_databases.tags IS 'Tags';
COMMENT ON COLUMN mca_env_base.duckdb_databases.internal IS 'Internal';
COMMENT ON COLUMN mca_env_base.duckdb_databases.type IS 'Type';
COMMENT ON COLUMN mca_env_base.duckdb_databases.readonly IS 'Readonly';
COMMENT ON COLUMN mca_env_base.duckdb_databases.encrypted IS 'Encrypted';
COMMENT ON COLUMN mca_env_base.duckdb_databases.cipher IS 'Cipher';

-- View: duckdb_indexes
COMMENT ON TABLE mca_env_base.duckdb_indexes IS 'View based on duckdb_indexes';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.schema_oid IS 'Schema oid';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.index_name IS 'Index name';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.index_oid IS 'Index oid';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.table_oid IS 'Table oid';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.tags IS 'Tags';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.is_unique IS 'Is unique';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.is_primary IS 'Is primary';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.expressions IS 'Expressions';
COMMENT ON COLUMN mca_env_base.duckdb_indexes.sql IS 'Sql';

-- View: duckdb_logs
COMMENT ON TABLE mca_env_base.duckdb_logs IS 'View based on duckdb_logs';
COMMENT ON COLUMN mca_env_base.duckdb_logs.context_id IS 'Context id';
COMMENT ON COLUMN mca_env_base.duckdb_logs.scope IS 'Scope';
COMMENT ON COLUMN mca_env_base.duckdb_logs.connection_id IS 'Connection id';
COMMENT ON COLUMN mca_env_base.duckdb_logs.transaction_id IS 'Transaction id';
COMMENT ON COLUMN mca_env_base.duckdb_logs.query_id IS 'Query id';
COMMENT ON COLUMN mca_env_base.duckdb_logs.thread_id IS 'Thread id';
COMMENT ON COLUMN mca_env_base.duckdb_logs.timestamp IS 'Timestamp';
COMMENT ON COLUMN mca_env_base.duckdb_logs.type IS 'Type';
COMMENT ON COLUMN mca_env_base.duckdb_logs.log_level IS 'Log level';
COMMENT ON COLUMN mca_env_base.duckdb_logs.message IS 'Message';

-- View: duckdb_schemas
COMMENT ON TABLE mca_env_base.duckdb_schemas IS 'View based on duckdb_schemas';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.tags IS 'Tags';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.internal IS 'Internal';
COMMENT ON COLUMN mca_env_base.duckdb_schemas.sql IS 'Sql';

-- View: duckdb_tables
COMMENT ON TABLE mca_env_base.duckdb_tables IS 'View based on duckdb_tables';
COMMENT ON COLUMN mca_env_base.duckdb_tables.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_tables.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_tables.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_tables.schema_oid IS 'Schema oid';
COMMENT ON COLUMN mca_env_base.duckdb_tables.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.duckdb_tables.table_oid IS 'Table oid';
COMMENT ON COLUMN mca_env_base.duckdb_tables.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_tables.tags IS 'Tags';
COMMENT ON COLUMN mca_env_base.duckdb_tables.internal IS 'Internal';
COMMENT ON COLUMN mca_env_base.duckdb_tables.temporary IS 'Temporary';
COMMENT ON COLUMN mca_env_base.duckdb_tables.has_primary_key IS 'Has primary key';
COMMENT ON COLUMN mca_env_base.duckdb_tables.estimated_size IS 'Estimated size';
COMMENT ON COLUMN mca_env_base.duckdb_tables.column_count IS 'Column count';
COMMENT ON COLUMN mca_env_base.duckdb_tables.index_count IS 'Index count';
COMMENT ON COLUMN mca_env_base.duckdb_tables.check_constraint_count IS 'Check constraint count';
COMMENT ON COLUMN mca_env_base.duckdb_tables.sql IS 'Sql';

-- View: duckdb_types
COMMENT ON TABLE mca_env_base.duckdb_types IS 'View based on duckdb_types';
COMMENT ON COLUMN mca_env_base.duckdb_types.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_types.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_types.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_types.schema_oid IS 'Schema oid';
COMMENT ON COLUMN mca_env_base.duckdb_types.type_oid IS 'Type oid';
COMMENT ON COLUMN mca_env_base.duckdb_types.type_name IS 'Type name';
COMMENT ON COLUMN mca_env_base.duckdb_types.type_size IS 'Type size';
COMMENT ON COLUMN mca_env_base.duckdb_types.logical_type IS 'Logical type';
COMMENT ON COLUMN mca_env_base.duckdb_types.type_category IS 'Type category';
COMMENT ON COLUMN mca_env_base.duckdb_types.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_types.tags IS 'Tags';
COMMENT ON COLUMN mca_env_base.duckdb_types.internal IS 'Internal';
COMMENT ON COLUMN mca_env_base.duckdb_types.labels IS 'Labels';

-- View: duckdb_views
COMMENT ON TABLE mca_env_base.duckdb_views IS 'View based on duckdb_views';
COMMENT ON COLUMN mca_env_base.duckdb_views.database_name IS 'Database name';
COMMENT ON COLUMN mca_env_base.duckdb_views.database_oid IS 'Database oid';
COMMENT ON COLUMN mca_env_base.duckdb_views.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.duckdb_views.schema_oid IS 'Schema oid';
COMMENT ON COLUMN mca_env_base.duckdb_views.view_name IS 'View name';
COMMENT ON COLUMN mca_env_base.duckdb_views.view_oid IS 'View oid';
COMMENT ON COLUMN mca_env_base.duckdb_views.comment IS 'Comment';
COMMENT ON COLUMN mca_env_base.duckdb_views.tags IS 'Tags';
COMMENT ON COLUMN mca_env_base.duckdb_views.internal IS 'Internal';
COMMENT ON COLUMN mca_env_base.duckdb_views.temporary IS 'Temporary';
COMMENT ON COLUMN mca_env_base.duckdb_views.column_count IS 'Column count';
COMMENT ON COLUMN mca_env_base.duckdb_views.sql IS 'Sql';

-- View: epc_domestic_lep_vw
COMMENT ON TABLE mca_env_base.epc_domestic_lep_vw IS 'View based on epc_domestic_vw, open_uprn_lep_tbl';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LMK_KEY IS 'Lmk key';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.BUILDING_REFERENCE_NUMBER IS 'Building reference number';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CURRENT_ENERGY_RATING IS 'Current energy rating';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.POTENTIAL_ENERGY_RATING IS 'Potential energy rating';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CURRENT_ENERGY_EFFICIENCY IS 'Current energy efficiency';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.POTENTIAL_ENERGY_EFFICIENCY IS 'Potential energy efficiency';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.PROPERTY_TYPE IS 'Property type';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.BUILT_FORM IS 'Built form';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.INSPECTION_DATE IS 'Inspection date';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LOCAL_AUTHORITY IS 'Local authority';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CONSTITUENCY IS 'Constituency';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.COUNTY IS 'County';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LODGEMENT_DATE IS 'Lodgement date';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.TRANSACTION_TYPE IS 'Transaction type';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ENVIRONMENT_IMPACT_CURRENT IS 'Environment impact current';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ENVIRONMENT_IMPACT_POTENTIAL IS 'Environment impact potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ENERGY_CONSUMPTION_CURRENT IS 'Energy consumption current';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ENERGY_CONSUMPTION_POTENTIAL IS 'Energy consumption potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CO2_EMISSIONS_CURRENT IS 'Co2 emissions current';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CO2_EMISS_CURR_PER_FLOOR_AREA IS 'Co2 emiss curr per floor area';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CO2_EMISSIONS_POTENTIAL IS 'Co2 emissions potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LIGHTING_COST_CURRENT IS 'Lighting cost current';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LIGHTING_COST_POTENTIAL IS 'Lighting cost potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HEATING_COST_CURRENT IS 'Heating cost current';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HEATING_COST_POTENTIAL IS 'Heating cost potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HOT_WATER_COST_CURRENT IS 'Hot water cost current';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HOT_WATER_COST_POTENTIAL IS 'Hot water cost potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.TOTAL_FLOOR_AREA IS 'Total floor area';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ENERGY_TARIFF IS 'Energy tariff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINS_GAS_FLAG IS 'Mains gas flag';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLOOR_LEVEL IS 'Floor level';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLAT_TOP_STOREY IS 'Flat top storey';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLAT_STOREY_COUNT IS 'Flat storey count';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAIN_HEATING_CONTROLS IS 'Main heating controls';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MULTI_GLAZE_PROPORTION IS 'Multi glaze proportion';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.GLAZED_TYPE IS 'Glazed type';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.GLAZED_AREA IS 'Glazed area';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.EXTENSION_COUNT IS 'Extension count';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.NUMBER_HABITABLE_ROOMS IS 'Number habitable rooms';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.NUMBER_HEATED_ROOMS IS 'Number heated rooms';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LOW_ENERGY_LIGHTING IS 'Low energy lighting';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.NUMBER_OPEN_FIREPLACES IS 'Number open fireplaces';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HOTWATER_DESCRIPTION IS 'Hotwater description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HOT_WATER_ENERGY_EFF IS 'Hot water energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HOT_WATER_ENV_EFF IS 'Hot water env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLOOR_DESCRIPTION IS 'Floor description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLOOR_ENERGY_EFF IS 'Floor energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLOOR_ENV_EFF IS 'Floor env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WINDOWS_DESCRIPTION IS 'Windows description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WINDOWS_ENERGY_EFF IS 'Windows energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WINDOWS_ENV_EFF IS 'Windows env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WALLS_DESCRIPTION IS 'Walls description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WALLS_ENERGY_EFF IS 'Walls energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WALLS_ENV_EFF IS 'Walls env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.SECONDHEAT_DESCRIPTION IS 'Secondheat description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.SHEATING_ENERGY_EFF IS 'Sheating energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.SHEATING_ENV_EFF IS 'Sheating env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ROOF_DESCRIPTION IS 'Roof description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ROOF_ENERGY_EFF IS 'Roof energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ROOF_ENV_EFF IS 'Roof env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINHEAT_DESCRIPTION IS 'Mainheat description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINHEAT_ENERGY_EFF IS 'Mainheat energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINHEAT_ENV_EFF IS 'Mainheat env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINHEATCONT_DESCRIPTION IS 'Mainheatcont description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINHEATC_ENERGY_EFF IS 'Mainheatc energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAINHEATC_ENV_EFF IS 'Mainheatc env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LIGHTING_DESCRIPTION IS 'Lighting description';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LIGHTING_ENERGY_EFF IS 'Lighting energy eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LIGHTING_ENV_EFF IS 'Lighting env eff';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MAIN_FUEL IS 'Main fuel';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.WIND_TURBINE_COUNT IS 'Wind turbine count';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.HEAT_LOSS_CORRIDOR IS 'Heat loss corridor';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.UNHEATED_CORRIDOR_LENGTH IS 'Unheated corridor length';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FLOOR_HEIGHT IS 'Floor height';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.PHOTO_SUPPLY IS 'Photo supply';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.SOLAR_WATER_HEATING_FLAG IS 'Solar water heating flag';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.MECHANICAL_VENTILATION IS 'Mechanical ventilation';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.ADDRESS IS 'Address';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LOCAL_AUTHORITY_LABEL IS 'Local authority label';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CONSTITUENCY_LABEL IS 'Constituency label';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.POSTTOWN IS 'Posttown';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CONSTRUCTION_AGE_BAND IS 'Construction age band';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LODGEMENT_DATETIME IS 'Lodgement datetime';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.TENURE IS 'Tenure';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.FIXED_LIGHTING_OUTLETS_COUNT IS 'Fixed lighting outlets count';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LOW_ENERGY_FIXED_LIGHT_COUNT IS 'Low energy fixed light count';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.UPRN IS 'Unique Property Reference Number';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.UPRN_SOURCE IS 'Uprn source';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.REPORT_TYPE IS 'Report type';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.NOMINAL_CONSTRUCTION_YEAR IS 'Nominal construction year';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.CONSTRUCTION_EPOCH IS 'Construction epoch';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.TENURE_CLEAN IS 'Tenure clean';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LODGEMENT_YEAR IS 'Lodgement year';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LODGEMENT_MONTH IS 'Lodgement month';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.LODGEMENT_DAY IS 'Lodgement day';
COMMENT ON COLUMN mca_env_base.epc_domestic_lep_vw.geo_point_2d IS 'Geo point 2d';

-- View: epc_domestic_vw
COMMENT ON TABLE mca_env_base.epc_domestic_vw IS 'View based on raw_domestic_epc_certificates_tbl';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LMK_KEY IS 'Individual lodgement identifier. Guaranteed to be unique and can be used to identify a certificate in the downloads and the API.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ADDRESS1 IS 'First line of the address';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ADDRESS2 IS 'Second line of the address';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ADDRESS3 IS 'Third line of the address';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.POSTCODE IS 'The postcode of the property';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.BUILDING_REFERENCE_NUMBER IS 'Unique identifier for the property.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CURRENT_ENERGY_RATING IS 'Current energy rating converted into a linear ''A to G'' rating (where A is the most energy efficient and G is the least energy efficient)';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.POTENTIAL_ENERGY_RATING IS 'Estimated potential energy rating converted into a linear ''A to G'' rating (where A is the most energy efficient and G is the least energy efficient)';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CURRENT_ENERGY_EFFICIENCY IS 'Based on cost of energy, i.e. energy required for space heating, water heating and lighting [in kWh/year] multiplied by fuel costs. (£/m²/year where cost is derived from kWh).';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.POTENTIAL_ENERGY_EFFICIENCY IS 'The potential energy efficiency rating of the property.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.PROPERTY_TYPE IS 'Describes the type of property such as House, Flat, Maisonette etc. This is the type differentiator for dwellings.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.BUILT_FORM IS 'The building type of the Property e.g. Detached, Semi-Detached, Terrace etc. Together with the Property Type, the Build Form produces a structured description of the property';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.INSPECTION_DATE IS 'The date that the inspection was actually carried out by the energy assessor';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LOCAL_AUTHORITY IS 'Office for National Statistics (ONS) code. Local authority area in which the building is located.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CONSTITUENCY IS 'Office for National Statistics (ONS) code. Parliamentary constituency in which the building is located.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.COUNTY IS 'County in which the building is located (where applicable)';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LODGEMENT_DATE IS 'Date lodged on the Energy Performance of Buildings Register';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.TRANSACTION_TYPE IS 'Type of transaction that triggered EPC. For example, one of: marketed sale; non-marketed sale; new-dwelling; rental; not sale or rental; assessment for Green Deal; following Green Deal; FIT application; none of the above; RHI application; ECO assessment. Where the reason for the assessment is unknown by the energy assessor the transaction type will be recorded as ''none of the above''. Transaction types may be changed over time.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ENVIRONMENT_IMPACT_CURRENT IS 'Environment impact current';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ENVIRONMENT_IMPACT_POTENTIAL IS 'Environment impact potential';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ENERGY_CONSUMPTION_CURRENT IS 'Current estimated total energy consumption for the property in a 12 month period (kWh/m2). Displayed on EPC as the current primary energy use per square metre of floor area.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ENERGY_CONSUMPTION_POTENTIAL IS 'Estimated potential total energy consumption for the Property in a 12 month period. Value is Kilowatt Hours per Square Metre (kWh/m²)';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CO2_EMISSIONS_CURRENT IS 'CO₂ emissions per year in tonnes/year.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CO2_EMISS_CURR_PER_FLOOR_AREA IS 'CO₂ emissions per square metre floor area per year in kg/m²';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CO2_EMISSIONS_POTENTIAL IS 'Estimated value in Tonnes per Year of the total CO₂ emissions produced by the Property in 12 month period.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LIGHTING_COST_CURRENT IS 'GBP. Current estimated annual energy costs for lighting the property.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LIGHTING_COST_POTENTIAL IS 'GBP. Potential estimated annual energy costs for lighting the property after improvements have been made.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HEATING_COST_CURRENT IS 'GBP. Current estimated annual energy costs for heating the property.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HEATING_COST_POTENTIAL IS 'GBP. Potential annual energy costs for lighting the property after improvements have been made.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HOT_WATER_COST_CURRENT IS 'GBP. Current estimated annual energy costs for hot water';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HOT_WATER_COST_POTENTIAL IS 'GBP. Potential estimated annual energy costs for hot water after improvements have been made.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.TOTAL_FLOOR_AREA IS 'The total useful floor area is the total of all enclosed spaces measured to the internal face of the external walls, i.e. the gross floor area as measured in accordance with the guidance issued from time to time by the Royal Institute of Chartered Surveyors or by a body replacing that institution. (m²)';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ENERGY_TARIFF IS 'Type of electricity tariff for the property, e.g. single.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINS_GAS_FLAG IS 'Whether mains gas is available. Yes means that there is a gas meter or a gas-burning appliance in the dwelling. A closed-off gas pipe does not count.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLOOR_LEVEL IS 'Flats and maisonettes only. Floor level relative to the lowest level of the property (0 for ground floor). If there is a basement, the basement is level 0 and the other floors are from 1 upwards';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLAT_TOP_STOREY IS 'Whether the flat is on the top storey';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLAT_STOREY_COUNT IS 'The number of storeys in the apartment block.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAIN_HEATING_CONTROLS IS 'Type of main heating controls. Includes both main heating systems if there are two.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MULTI_GLAZE_PROPORTION IS 'The estimated banded range (e.g. 0% - 10%) of the total glazed area of the Property that is multiple glazed.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.GLAZED_TYPE IS 'The type of glazing. From British Fenestration Rating Council or manufacturer declaration, one of; single; double; triple.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.GLAZED_AREA IS 'Ranged estimate of the total glazed area of the Habitable Area.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.EXTENSION_COUNT IS 'The number of extensions added to the property. Between 0 and 4.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.NUMBER_HABITABLE_ROOMS IS 'Habitable rooms include any living room, sitting room, dining room, bedroom, study and similar; and also a non-separated conservatory. A kitchen/diner having a discrete seating area (with space for a table and four chairs) also counts as a habitable room. A non-separated conservatory adds to the habitable room count if it has an internal quality door between it and the dwelling. Excluded from the room count are any room used solely as a kitchen, utility room, bathroom, cloakroom, en-suite accommodation and similar and any hallway, stairs or landing; and also any room not having a window.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.NUMBER_HEATED_ROOMS IS 'The number of heated rooms in the property if more than half of the habitable rooms are not heated.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LOW_ENERGY_LIGHTING IS 'The percentage of low energy lighting present in the property as a percentage of the total fixed lights in the property. 0% indicates that no low-energy lighting is present.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.NUMBER_OPEN_FIREPLACES IS 'The number of Open Fireplaces in the Property. An Open Fireplace is a fireplace that still allows air to pass between the inside of the Property and the outside.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HOTWATER_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HOT_WATER_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HOT_WATER_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLOOR_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLOOR_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLOOR_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WINDOWS_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WINDOWS_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WINDOWS_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WALLS_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WALLS_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WALLS_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.SECONDHEAT_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.SHEATING_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.SHEATING_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ROOF_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ROOF_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ROOF_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINHEAT_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINHEAT_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINHEAT_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINHEATCONT_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINHEATC_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAINHEATC_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LIGHTING_DESCRIPTION IS 'Overall description of the property feature';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LIGHTING_ENERGY_EFF IS 'Energy efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LIGHTING_ENV_EFF IS 'Environmental efficiency rating. One of: very good; good; average; poor; very poor. On actual energy certificate shown as one to five star rating.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MAIN_FUEL IS 'The type of fuel used to power the central heating e.g. Gas, Electricity';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.WIND_TURBINE_COUNT IS 'Number of wind turbines; 0 if none.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.HEAT_LOSS_CORRIDOR IS 'Flats and maisonettes only. Indicates that the flat contains a corridor through which heat is lost. Heat loss corridor, one of: no corridor; heated corridor; unheated corridor';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.UNHEATED_CORRIDOR_LENGTH IS 'The total length of unheated corridor in the flat. Only populated if flat or maisonette contains unheated corridor. If unheated corridor, length of sheltered wall (m²).';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FLOOR_HEIGHT IS 'Average height of the storey in metres.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.PHOTO_SUPPLY IS 'Percentage of photovoltaic area as a percentage of total roof area. 0% indicates that a Photovoltaic Supply is not present in the property.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.SOLAR_WATER_HEATING_FLAG IS 'Indicates whether the heating in the Property is solar powered.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.MECHANICAL_VENTILATION IS 'Identifies the type of mechanical ventilation the property has. This is required for the RdSAP calculation.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.ADDRESS IS 'Field containing the concatenation of address1, address2 and address3. Note that post code is recorded separately.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LOCAL_AUTHORITY_LABEL IS 'The name of the local authority area in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Local Authority ONS Code.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CONSTITUENCY_LABEL IS 'The name of the parliamentary constituency in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Constituency ONS Code.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.POSTTOWN IS 'The post town of the property';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CONSTRUCTION_AGE_BAND IS 'Age band when building part constructed. England & Wales only. One of: before 1900; 1900-1929; 1930-1949; 1950-1966; 1967-1975; 1976-1982; 1983-1990; 1991-1995; 1996-2002; 2003-2006; 2007-2011; 2012 onwards.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LODGEMENT_DATETIME IS 'Date and time lodged on the Energy Performance of Buildings Register.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.TENURE IS 'Describes the tenure type of the property. One of: Owner-occupied; Rented (social); Rented (private).';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.FIXED_LIGHTING_OUTLETS_COUNT IS 'The number of fixed lighting outlets.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LOW_ENERGY_FIXED_LIGHT_COUNT IS 'The number of low-energy fixed lighting outlets.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.UPRN IS 'The UPRN submitted by an assessor or alternatively from the department’s address matching algorithm.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.UPRN_SOURCE IS 'Populated with the values "Energy Assessor" or "Address Matched" to show how the UPRN was populated.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.REPORT_TYPE IS 'Type of assessment carried out on the building, for domestic dwellings this is either a SAP (Standard Assessment Procedure) or a Reduced SAP. 100: RdSAP (Reduced SAP for existing buildings) and 101: SAP (full Sap for new dwellings, including conversions and change of use). This variable will help distinguish between new and existing dwellings.';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.NOMINAL_CONSTRUCTION_YEAR IS 'Computed field: NOMINAL_CONSTRUCTION_YEAR';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.CONSTRUCTION_EPOCH IS 'Computed field: CONSTRUCTION_EPOCH';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.TENURE_CLEAN IS 'Computed field: TENURE_CLEAN';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LODGEMENT_YEAR IS 'Computed field: LODGEMENT_YEAR';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LODGEMENT_MONTH IS 'Computed field: LODGEMENT_MONTH';
COMMENT ON COLUMN mca_env_base.epc_domestic_vw.LODGEMENT_DAY IS 'Computed field: LODGEMENT_DAY';

-- View: epc_non_domestic_lep_vw
COMMENT ON TABLE mca_env_base.epc_non_domestic_lep_vw IS 'View based on raw_non_domestic_epc_certificates_tbl, open_uprn_lep_tbl';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.LMK_KEY IS 'Individual lodgement identifier. Guaranteed to be unique and can be used to identify a certificate in the downloads and the API.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ADDRESS1 IS 'First line of the address';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ADDRESS2 IS 'Second line of the address';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ADDRESS3 IS 'Third line of the address';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.POSTCODE IS 'The postcode of the property';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.BUILDING_REFERENCE_NUMBER IS 'Unique identifier for the property.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ASSET_RATING IS 'Energy Performance Asset Rating. The CO₂ emissions from the actual building in comparison to a Standard Emission Rate. (kg CO₂/m²)';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ASSET_RATING_BAND IS 'Energy Performance Asset Rating converted into an energy band/grade into a linear ''A+ to G'' scale (where A+ is the most energy efficient and G the least energy efficient)';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.PROPERTY_TYPE IS 'Describes the type of building that is being inspected. Based on planning use class.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.INSPECTION_DATE IS 'The date that the inspection was actually carried out by the energy assessor';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.LOCAL_AUTHORITY IS 'Office for National Statistics (ONS) code. Local authority area in which the building is located.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.CONSTITUENCY IS 'Office for National Statistics (ONS) code. Parliamentary constituency in which the building is located.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.COUNTY IS 'County in which the building is located (where applicable)';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.LODGEMENT_DATE IS 'Date lodged on the Energy Performance of Buildings Register';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.TRANSACTION_TYPE IS 'Type of transaction that triggered EPC. One of: mandatory issue (marketed sale); mandatory issue (non-marketed sale); mandatory issue (property on construction); mandatory issue (property to let); voluntary re-issue (a valid epc is already lodged); voluntary (no legal requirement for an epc); not recorded. Transaction types may be changed over time.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.NEW_BUILD_BENCHMARK IS 'NEW_BUILD_BENCHMARK';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.EXISTING_STOCK_BENCHMARK IS 'The Benchmark value of existing stock for this type of building';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.BUILDING_LEVEL IS 'Building Complexity Level based on Energy Assessor National Occupation Standards';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.MAIN_HEATING_FUEL IS 'Main Heating fuel for the building is taken as the fuel which delivers the greatest total thermal output for space or water heating';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.OTHER_FUEL_DESC IS 'Text description of unspecified fuel type if ''Other'' is selected for Main Heating Fuel';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.SPECIAL_ENERGY_USES IS 'Special energy uses discounted. This only appears on the Recommendations Report.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.RENEWABLE_SOURCES IS 'On-site renewable energy sources. This only appears on the Advisory Report.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.FLOOR_AREA IS 'The total useful floor area is the total of all enclosed spaces measured to the internal face of the external walls, i.e. the gross floor area as measured in accordance with the guidance issued from time to time by the Royal Institute of Chartered Surveyors or by a body replacing that institution. (m2)';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.STANDARD_EMISSIONS IS 'Standard Emission Rate is determined by applying a fixed improvement factor to the emissions from a reference building. (kg CO₂/m²/year).';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.TARGET_EMISSIONS IS 'Standard Emission Rate is determined by applying a fixed improvement factor to the emissions from a reference building. (kg CO₂/m²/year).';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.TYPICAL_EMISSIONS IS 'Typical Emission Rate.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.BUILDING_EMISSIONS IS 'Building Emissions Rate. Annual CO₂ emissions from the building. Decimal (kg CO₂/m²)';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.AIRCON_PRESENT IS 'Air Conditioning System. Does the building have an air conditioning system?';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.AIRCON_KW_RATING IS 'Air conditioning System. Rating in kW';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ESTIMATED_AIRCON_KW_RATING IS 'Air Conditioning System. If exact rating unknown, what is the estimated total effective output rating of the air conditioning system';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.AC_INSPECTION_COMMISSIONED IS 'One of:1=Yes, inspection completed; 2=Yes, inspection commissioned; 3=No inspection completed or commissioned; 4=Not relevant; 5=Don''t know';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.BUILDING_ENVIRONMENT IS 'Building environment which is taken as the servicing strategy that contributes the largest proportion of the building''s CO₂ emissions.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.ADDRESS IS 'Field containing the concatenation of address1, address2 and address3. Note that post code is recorded separately.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.LOCAL_AUTHORITY_LABEL IS 'The name of the local authority area in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Local Authority ONS Code.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.CONSTITUENCY_LABEL IS 'The name of the parliamentary constituency in which the building is located. This field is for additional information only and should not be relied upon: please refer to the Constituency ONS Code.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.POSTTOWN IS 'The post town of the property';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.LODGEMENT_DATETIME IS 'Date and time lodged on the Energy Performance of Buildings Register.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.PRIMARY_ENERGY_VALUE IS 'Displayed on the non-domestic EPC as primary energy use (kWh/m2 per year)';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.UPRN IS 'The UPRN submitted by an assessor or alternatively from the department’s address matching algorithm.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.UPRN_SOURCE IS 'Populated with the values "Energy Assessor" or "Address Matched" to show how the UPRN was populated.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.REPORT_TYPE IS 'Type of assessment carried out of the building. 102: assessment using the SBEM (Simplified Building Energy Model) tool for non-domestic (non-residential) buildings.';
COMMENT ON COLUMN mca_env_base.epc_non_domestic_lep_vw.geo_point_2d IS 'Geo point 2d';

-- View: key_column_usage
COMMENT ON TABLE mca_env_base.key_column_usage IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.key_column_usage.constraint_catalog IS 'Constraint catalog';
COMMENT ON COLUMN mca_env_base.key_column_usage.constraint_schema IS 'Constraint schema';
COMMENT ON COLUMN mca_env_base.key_column_usage.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.key_column_usage.table_catalog IS 'Table catalog';
COMMENT ON COLUMN mca_env_base.key_column_usage.table_schema IS 'Table schema';
COMMENT ON COLUMN mca_env_base.key_column_usage.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.key_column_usage.column_name IS 'Column name';
COMMENT ON COLUMN mca_env_base.key_column_usage.ordinal_position IS 'Ordinal position';
COMMENT ON COLUMN mca_env_base.key_column_usage.position_in_unique_constraint IS 'Computed field: position_in_unique_constraint';

-- View: per_cap_emissions_ca_national_vw
COMMENT ON TABLE mca_env_base.per_cap_emissions_ca_national_vw IS 'View based on la_ghg_emissions_wide_tbl, ca_la_lookup_inc_ns_vw';
COMMENT ON COLUMN mca_env_base.per_cap_emissions_ca_national_vw.calendar_year IS 'Calendar year';
COMMENT ON COLUMN mca_env_base.per_cap_emissions_ca_national_vw.area IS 'Area';
COMMENT ON COLUMN mca_env_base.per_cap_emissions_ca_national_vw.per_cap IS 'Per cap';

-- View: pg_am
COMMENT ON TABLE mca_env_base.pg_am IS 'View: pg_am';
COMMENT ON COLUMN mca_env_base.pg_am.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_am.amname IS 'Amname';
COMMENT ON COLUMN mca_env_base.pg_am.amhandler IS 'Amhandler';
COMMENT ON COLUMN mca_env_base.pg_am.amtype IS 'Amtype';

-- View: pg_attrdef
COMMENT ON TABLE mca_env_base.pg_attrdef IS 'View based on duckdb_columns';
COMMENT ON COLUMN mca_env_base.pg_attrdef.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_attrdef.adrelid IS 'Adrelid';
COMMENT ON COLUMN mca_env_base.pg_attrdef.adnum IS 'Adnum';
COMMENT ON COLUMN mca_env_base.pg_attrdef.adbin IS 'Adbin';

-- View: pg_attribute
COMMENT ON TABLE mca_env_base.pg_attribute IS 'View based on duckdb_columns';
COMMENT ON COLUMN mca_env_base.pg_attribute.attrelid IS 'Attrelid';
COMMENT ON COLUMN mca_env_base.pg_attribute.attname IS 'Attname';
COMMENT ON COLUMN mca_env_base.pg_attribute.atttypid IS 'Atttypid';
COMMENT ON COLUMN mca_env_base.pg_attribute.attstattarget IS 'Attstattarget';
COMMENT ON COLUMN mca_env_base.pg_attribute.attlen IS 'Attlen';
COMMENT ON COLUMN mca_env_base.pg_attribute.attnum IS 'Attnum';
COMMENT ON COLUMN mca_env_base.pg_attribute.attndims IS 'Attndims';
COMMENT ON COLUMN mca_env_base.pg_attribute.attcacheoff IS 'Attcacheoff';
COMMENT ON COLUMN mca_env_base.pg_attribute.atttypmod IS 'Computed field: atttypmod';
COMMENT ON COLUMN mca_env_base.pg_attribute.attbyval IS 'Computed field: attbyval';
COMMENT ON COLUMN mca_env_base.pg_attribute.attstorage IS 'Computed field: attstorage';
COMMENT ON COLUMN mca_env_base.pg_attribute.attalign IS 'Computed field: attalign';
COMMENT ON COLUMN mca_env_base.pg_attribute.attnotnull IS 'Computed field: attnotnull';
COMMENT ON COLUMN mca_env_base.pg_attribute.atthasdef IS 'Computed field: atthasdef';
COMMENT ON COLUMN mca_env_base.pg_attribute.atthasmissing IS 'Computed field: atthasmissing';
COMMENT ON COLUMN mca_env_base.pg_attribute.attidentity IS 'Computed field: attidentity';
COMMENT ON COLUMN mca_env_base.pg_attribute.attgenerated IS 'Computed field: attgenerated';
COMMENT ON COLUMN mca_env_base.pg_attribute.attisdropped IS 'Computed field: attisdropped';
COMMENT ON COLUMN mca_env_base.pg_attribute.attislocal IS 'Computed field: attislocal';
COMMENT ON COLUMN mca_env_base.pg_attribute.attinhcount IS 'Computed field: attinhcount';
COMMENT ON COLUMN mca_env_base.pg_attribute.attcollation IS 'Computed field: attcollation';
COMMENT ON COLUMN mca_env_base.pg_attribute.attcompression IS 'Computed field: attcompression';
COMMENT ON COLUMN mca_env_base.pg_attribute.attacl IS 'Computed field: attacl';
COMMENT ON COLUMN mca_env_base.pg_attribute.attoptions IS 'Computed field: attoptions';
COMMENT ON COLUMN mca_env_base.pg_attribute.attfdwoptions IS 'Computed field: attfdwoptions';
COMMENT ON COLUMN mca_env_base.pg_attribute.attmissingval IS 'Computed field: attmissingval';

-- View: pg_class
COMMENT ON TABLE mca_env_base.pg_class IS 'View based on duckdb_tables, duckdb_views, duckdb_sequences, duckdb_indexes';
COMMENT ON COLUMN mca_env_base.pg_class.oid IS 'Computed field: oid';
COMMENT ON COLUMN mca_env_base.pg_class.relname IS 'Computed field: relname';
COMMENT ON COLUMN mca_env_base.pg_class.relnamespace IS 'Computed field: relnamespace';
COMMENT ON COLUMN mca_env_base.pg_class.reltype IS 'Computed field: reltype';
COMMENT ON COLUMN mca_env_base.pg_class.reloftype IS 'Computed field: reloftype';
COMMENT ON COLUMN mca_env_base.pg_class.relowner IS 'Computed field: relowner';
COMMENT ON COLUMN mca_env_base.pg_class.relam IS 'Computed field: relam';
COMMENT ON COLUMN mca_env_base.pg_class.relfilenode IS 'Computed field: relfilenode';
COMMENT ON COLUMN mca_env_base.pg_class.reltablespace IS 'Computed field: reltablespace';
COMMENT ON COLUMN mca_env_base.pg_class.relpages IS 'Computed field: relpages';
COMMENT ON COLUMN mca_env_base.pg_class.reltuples IS 'Computed field: reltuples';
COMMENT ON COLUMN mca_env_base.pg_class.relallvisible IS 'Computed field: relallvisible';
COMMENT ON COLUMN mca_env_base.pg_class.reltoastrelid IS 'Computed field: reltoastrelid';
COMMENT ON COLUMN mca_env_base.pg_class.reltoastidxid IS 'Computed field: reltoastidxid';
COMMENT ON COLUMN mca_env_base.pg_class.relhasindex IS 'Computed field: relhasindex';
COMMENT ON COLUMN mca_env_base.pg_class.relisshared IS 'Computed field: relisshared';
COMMENT ON COLUMN mca_env_base.pg_class.relpersistence IS 'Computed field: relpersistence';
COMMENT ON COLUMN mca_env_base.pg_class.relkind IS 'Computed field: relkind';
COMMENT ON COLUMN mca_env_base.pg_class.relnatts IS 'Computed field: relnatts';
COMMENT ON COLUMN mca_env_base.pg_class.relchecks IS 'Computed field: relchecks';
COMMENT ON COLUMN mca_env_base.pg_class.relhasoids IS 'Computed field: relhasoids';
COMMENT ON COLUMN mca_env_base.pg_class.relhaspkey IS 'Computed field: relhaspkey';
COMMENT ON COLUMN mca_env_base.pg_class.relhasrules IS 'Computed field: relhasrules';
COMMENT ON COLUMN mca_env_base.pg_class.relhastriggers IS 'Computed field: relhastriggers';
COMMENT ON COLUMN mca_env_base.pg_class.relhassubclass IS 'Computed field: relhassubclass';
COMMENT ON COLUMN mca_env_base.pg_class.relrowsecurity IS 'Computed field: relrowsecurity';
COMMENT ON COLUMN mca_env_base.pg_class.relispopulated IS 'Computed field: relispopulated';
COMMENT ON COLUMN mca_env_base.pg_class.relreplident IS 'Computed field: relreplident';
COMMENT ON COLUMN mca_env_base.pg_class.relispartition IS 'Computed field: relispartition';
COMMENT ON COLUMN mca_env_base.pg_class.relrewrite IS 'Computed field: relrewrite';
COMMENT ON COLUMN mca_env_base.pg_class.relfrozenxid IS 'Computed field: relfrozenxid';
COMMENT ON COLUMN mca_env_base.pg_class.relminmxid IS 'Computed field: relminmxid';
COMMENT ON COLUMN mca_env_base.pg_class.relacl IS 'Computed field: relacl';
COMMENT ON COLUMN mca_env_base.pg_class.reloptions IS 'Computed field: reloptions';
COMMENT ON COLUMN mca_env_base.pg_class.relpartbound IS 'Computed field: relpartbound';

-- View: pg_constraint
COMMENT ON TABLE mca_env_base.pg_constraint IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.pg_constraint.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_constraint.conname IS 'Conname';
COMMENT ON COLUMN mca_env_base.pg_constraint.connamespace IS 'Connamespace';
COMMENT ON COLUMN mca_env_base.pg_constraint.contype IS 'Computed field: contype';
COMMENT ON COLUMN mca_env_base.pg_constraint.condeferrable IS 'Computed field: condeferrable';
COMMENT ON COLUMN mca_env_base.pg_constraint.condeferred IS 'Computed field: condeferred';
COMMENT ON COLUMN mca_env_base.pg_constraint.convalidated IS 'Computed field: convalidated';
COMMENT ON COLUMN mca_env_base.pg_constraint.conrelid IS 'Computed field: conrelid';
COMMENT ON COLUMN mca_env_base.pg_constraint.contypid IS 'Computed field: contypid';
COMMENT ON COLUMN mca_env_base.pg_constraint.conindid IS 'Computed field: conindid';
COMMENT ON COLUMN mca_env_base.pg_constraint.conparentid IS 'Computed field: conparentid';
COMMENT ON COLUMN mca_env_base.pg_constraint.confrelid IS 'Computed field: confrelid';
COMMENT ON COLUMN mca_env_base.pg_constraint.confupdtype IS 'Computed field: confupdtype';
COMMENT ON COLUMN mca_env_base.pg_constraint.confdeltype IS 'Computed field: confdeltype';
COMMENT ON COLUMN mca_env_base.pg_constraint.confmatchtype IS 'Computed field: confmatchtype';
COMMENT ON COLUMN mca_env_base.pg_constraint.conislocal IS 'Computed field: conislocal';
COMMENT ON COLUMN mca_env_base.pg_constraint.coninhcount IS 'Computed field: coninhcount';
COMMENT ON COLUMN mca_env_base.pg_constraint.connoinherit IS 'Computed field: connoinherit';
COMMENT ON COLUMN mca_env_base.pg_constraint.conkey IS 'Computed field: conkey';
COMMENT ON COLUMN mca_env_base.pg_constraint.confkey IS 'Computed field: confkey';
COMMENT ON COLUMN mca_env_base.pg_constraint.conpfeqop IS 'Computed field: conpfeqop';
COMMENT ON COLUMN mca_env_base.pg_constraint.conppeqop IS 'Computed field: conppeqop';
COMMENT ON COLUMN mca_env_base.pg_constraint.conffeqop IS 'Computed field: conffeqop';
COMMENT ON COLUMN mca_env_base.pg_constraint.conexclop IS 'Computed field: conexclop';
COMMENT ON COLUMN mca_env_base.pg_constraint.conbin IS 'Computed field: conbin';

-- View: pg_database
COMMENT ON TABLE mca_env_base.pg_database IS 'View based on duckdb_databases';
COMMENT ON COLUMN mca_env_base.pg_database.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_database.datname IS 'Datname';

-- View: pg_depend
COMMENT ON TABLE mca_env_base.pg_depend IS 'View based on duckdb_dependencies';
COMMENT ON COLUMN mca_env_base.pg_depend.classid IS 'Classid';
COMMENT ON COLUMN mca_env_base.pg_depend.objid IS 'Objid';
COMMENT ON COLUMN mca_env_base.pg_depend.objsubid IS 'Objsubid';
COMMENT ON COLUMN mca_env_base.pg_depend.refclassid IS 'Refclassid';
COMMENT ON COLUMN mca_env_base.pg_depend.refobjid IS 'Refobjid';
COMMENT ON COLUMN mca_env_base.pg_depend.refobjsubid IS 'Refobjsubid';
COMMENT ON COLUMN mca_env_base.pg_depend.deptype IS 'Deptype';

-- View: pg_description
COMMENT ON TABLE mca_env_base.pg_description IS 'View based on duckdb_tables, duckdb_columns, duckdb_views, duckdb_indexes, duckdb_sequences, duckdb_types, duckdb_functions';
COMMENT ON COLUMN mca_env_base.pg_description.objoid IS 'Objoid';
COMMENT ON COLUMN mca_env_base.pg_description.classoid IS 'Classoid';
COMMENT ON COLUMN mca_env_base.pg_description.objsubid IS 'Objsubid';
COMMENT ON COLUMN mca_env_base.pg_description.description IS 'Description';

-- View: pg_enum
COMMENT ON TABLE mca_env_base.pg_enum IS 'View based on duckdb_types';
COMMENT ON COLUMN mca_env_base.pg_enum.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_enum.enumtypid IS 'Enumtypid';
COMMENT ON COLUMN mca_env_base.pg_enum.enumsortorder IS 'Enumsortorder';
COMMENT ON COLUMN mca_env_base.pg_enum.enumlabel IS 'Enumlabel';

-- View: pg_index
COMMENT ON TABLE mca_env_base.pg_index IS 'View based on duckdb_indexes';
COMMENT ON COLUMN mca_env_base.pg_index.indexrelid IS 'Indexrelid';
COMMENT ON COLUMN mca_env_base.pg_index.indrelid IS 'Indrelid';
COMMENT ON COLUMN mca_env_base.pg_index.indnatts IS 'Indnatts';
COMMENT ON COLUMN mca_env_base.pg_index.indnkeyatts IS 'Indnkeyatts';
COMMENT ON COLUMN mca_env_base.pg_index.indisunique IS 'Indisunique';
COMMENT ON COLUMN mca_env_base.pg_index.indisprimary IS 'Indisprimary';
COMMENT ON COLUMN mca_env_base.pg_index.indisexclusion IS 'Computed field: indisexclusion';
COMMENT ON COLUMN mca_env_base.pg_index.indimmediate IS 'Computed field: indimmediate';
COMMENT ON COLUMN mca_env_base.pg_index.indisclustered IS 'Computed field: indisclustered';
COMMENT ON COLUMN mca_env_base.pg_index.indisvalid IS 'Computed field: indisvalid';
COMMENT ON COLUMN mca_env_base.pg_index.indcheckxmin IS 'Computed field: indcheckxmin';
COMMENT ON COLUMN mca_env_base.pg_index.indisready IS 'Computed field: indisready';
COMMENT ON COLUMN mca_env_base.pg_index.indislive IS 'Computed field: indislive';
COMMENT ON COLUMN mca_env_base.pg_index.indisreplident IS 'Computed field: indisreplident';
COMMENT ON COLUMN mca_env_base.pg_index.indkey IS 'Computed field: indkey';
COMMENT ON COLUMN mca_env_base.pg_index.indcollation IS 'Computed field: indcollation';
COMMENT ON COLUMN mca_env_base.pg_index.indclass IS 'Computed field: indclass';
COMMENT ON COLUMN mca_env_base.pg_index.indoption IS 'Computed field: indoption';
COMMENT ON COLUMN mca_env_base.pg_index.indexprs IS 'Computed field: indexprs';
COMMENT ON COLUMN mca_env_base.pg_index.indpred IS 'Computed field: indpred';

-- View: pg_indexes
COMMENT ON TABLE mca_env_base.pg_indexes IS 'View based on duckdb_indexes';
COMMENT ON COLUMN mca_env_base.pg_indexes.schemaname IS 'Schemaname';
COMMENT ON COLUMN mca_env_base.pg_indexes.tablename IS 'Tablename';
COMMENT ON COLUMN mca_env_base.pg_indexes.indexname IS 'Indexname';
COMMENT ON COLUMN mca_env_base.pg_indexes.tablespace IS 'Tablespace';
COMMENT ON COLUMN mca_env_base.pg_indexes.indexdef IS 'Indexdef';

-- View: pg_namespace
COMMENT ON TABLE mca_env_base.pg_namespace IS 'View based on duckdb_schemas';
COMMENT ON COLUMN mca_env_base.pg_namespace.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_namespace.nspname IS 'Nspname';
COMMENT ON COLUMN mca_env_base.pg_namespace.nspowner IS 'Nspowner';
COMMENT ON COLUMN mca_env_base.pg_namespace.nspacl IS 'Nspacl';

-- View: pg_prepared_statements
COMMENT ON TABLE mca_env_base.pg_prepared_statements IS 'View based on duckdb_prepared_statements';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.name IS 'Name';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.statement IS 'Statement';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.prepare_time IS 'Prepare time';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.parameter_types IS 'Parameter types';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.result_types IS 'Result types';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.from_sql IS 'From sql';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.generic_plans IS 'Generic plans';
COMMENT ON COLUMN mca_env_base.pg_prepared_statements.custom_plans IS 'Custom plans';

-- View: pg_proc
COMMENT ON TABLE mca_env_base.pg_proc IS 'View based on duckdb_functions, duckdb_schemas';
COMMENT ON COLUMN mca_env_base.pg_proc.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_proc.proname IS 'Proname';
COMMENT ON COLUMN mca_env_base.pg_proc.pronamespace IS 'Pronamespace';
COMMENT ON COLUMN mca_env_base.pg_proc.proowner IS 'Proowner';
COMMENT ON COLUMN mca_env_base.pg_proc.prolang IS 'Prolang';
COMMENT ON COLUMN mca_env_base.pg_proc.procost IS 'Procost';
COMMENT ON COLUMN mca_env_base.pg_proc.prorows IS 'Prorows';
COMMENT ON COLUMN mca_env_base.pg_proc.provariadic IS 'Provariadic';
COMMENT ON COLUMN mca_env_base.pg_proc.prosupport IS 'Prosupport';
COMMENT ON COLUMN mca_env_base.pg_proc.prokind IS 'Computed field: prokind';
COMMENT ON COLUMN mca_env_base.pg_proc.prosecdef IS 'Computed field: prosecdef';
COMMENT ON COLUMN mca_env_base.pg_proc.proleakproof IS 'Computed field: proleakproof';
COMMENT ON COLUMN mca_env_base.pg_proc.proisstrict IS 'Computed field: proisstrict';
COMMENT ON COLUMN mca_env_base.pg_proc.proretset IS 'Computed field: proretset';
COMMENT ON COLUMN mca_env_base.pg_proc.provolatile IS 'Computed field: provolatile';
COMMENT ON COLUMN mca_env_base.pg_proc.proparallel IS 'Computed field: proparallel';
COMMENT ON COLUMN mca_env_base.pg_proc.pronargs IS 'Computed field: pronargs';
COMMENT ON COLUMN mca_env_base.pg_proc.pronargdefaults IS 'Computed field: pronargdefaults';
COMMENT ON COLUMN mca_env_base.pg_proc.prorettype IS 'Computed field: prorettype';
COMMENT ON COLUMN mca_env_base.pg_proc.proargtypes IS 'Computed field: proargtypes';
COMMENT ON COLUMN mca_env_base.pg_proc.proallargtypes IS 'Computed field: proallargtypes';
COMMENT ON COLUMN mca_env_base.pg_proc.proargmodes IS 'Computed field: proargmodes';
COMMENT ON COLUMN mca_env_base.pg_proc.proargnames IS 'Computed field: proargnames';
COMMENT ON COLUMN mca_env_base.pg_proc.proargdefaults IS 'Computed field: proargdefaults';
COMMENT ON COLUMN mca_env_base.pg_proc.protrftypes IS 'Computed field: protrftypes';
COMMENT ON COLUMN mca_env_base.pg_proc.prosrc IS 'Computed field: prosrc';
COMMENT ON COLUMN mca_env_base.pg_proc.probin IS 'Computed field: probin';
COMMENT ON COLUMN mca_env_base.pg_proc.prosqlbody IS 'Computed field: prosqlbody';
COMMENT ON COLUMN mca_env_base.pg_proc.proconfig IS 'Computed field: proconfig';
COMMENT ON COLUMN mca_env_base.pg_proc.proacl IS 'Computed field: proacl';
COMMENT ON COLUMN mca_env_base.pg_proc.proisagg IS 'Computed field: proisagg';

-- View: pg_sequence
COMMENT ON TABLE mca_env_base.pg_sequence IS 'View based on duckdb_sequences';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqrelid IS 'Seqrelid';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqtypid IS 'Seqtypid';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqstart IS 'Seqstart';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqincrement IS 'Seqincrement';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqmax IS 'Seqmax';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqmin IS 'Seqmin';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqcache IS 'Seqcache';
COMMENT ON COLUMN mca_env_base.pg_sequence.seqcycle IS 'Seqcycle';

-- View: pg_sequences
COMMENT ON TABLE mca_env_base.pg_sequences IS 'View based on duckdb_sequences';
COMMENT ON COLUMN mca_env_base.pg_sequences.schemaname IS 'Schemaname';
COMMENT ON COLUMN mca_env_base.pg_sequences.sequencename IS 'Sequencename';
COMMENT ON COLUMN mca_env_base.pg_sequences.sequenceowner IS 'Sequenceowner';
COMMENT ON COLUMN mca_env_base.pg_sequences.data_type IS 'Data type';
COMMENT ON COLUMN mca_env_base.pg_sequences.start_value IS 'Start value';
COMMENT ON COLUMN mca_env_base.pg_sequences.min_value IS 'Min value';
COMMENT ON COLUMN mca_env_base.pg_sequences.max_value IS 'Max value';
COMMENT ON COLUMN mca_env_base.pg_sequences.increment_by IS 'Increment by';
COMMENT ON COLUMN mca_env_base.pg_sequences.cycle IS 'Cycle';
COMMENT ON COLUMN mca_env_base.pg_sequences.cache_size IS 'Cache size';
COMMENT ON COLUMN mca_env_base.pg_sequences.last_value IS 'Last value';

-- View: pg_settings
COMMENT ON TABLE mca_env_base.pg_settings IS 'View based on duckdb_settings';
COMMENT ON COLUMN mca_env_base.pg_settings.name IS 'Name';
COMMENT ON COLUMN mca_env_base.pg_settings.setting IS 'Setting';
COMMENT ON COLUMN mca_env_base.pg_settings.short_desc IS 'Short desc';
COMMENT ON COLUMN mca_env_base.pg_settings.vartype IS 'Computed field: vartype';

-- View: pg_tables
COMMENT ON TABLE mca_env_base.pg_tables IS 'View based on duckdb_tables';
COMMENT ON COLUMN mca_env_base.pg_tables.schemaname IS 'Schemaname';
COMMENT ON COLUMN mca_env_base.pg_tables.tablename IS 'Tablename';
COMMENT ON COLUMN mca_env_base.pg_tables.tableowner IS 'Tableowner';
COMMENT ON COLUMN mca_env_base.pg_tables.tablespace IS 'Tablespace';
COMMENT ON COLUMN mca_env_base.pg_tables.hasindexes IS 'Hasindexes';
COMMENT ON COLUMN mca_env_base.pg_tables.hasrules IS 'Computed field: hasrules';
COMMENT ON COLUMN mca_env_base.pg_tables.hastriggers IS 'Computed field: hastriggers';

-- View: pg_tablespace
COMMENT ON TABLE mca_env_base.pg_tablespace IS 'View: pg_tablespace';
COMMENT ON COLUMN mca_env_base.pg_tablespace.oid IS 'Oid';
COMMENT ON COLUMN mca_env_base.pg_tablespace.spcname IS 'Spcname';
COMMENT ON COLUMN mca_env_base.pg_tablespace.spcowner IS 'Spcowner';
COMMENT ON COLUMN mca_env_base.pg_tablespace.spcacl IS 'Spcacl';
COMMENT ON COLUMN mca_env_base.pg_tablespace.spcoptions IS 'Spcoptions';

-- View: pg_type
COMMENT ON TABLE mca_env_base.pg_type IS 'View based on duckdb_types';
COMMENT ON COLUMN mca_env_base.pg_type.oid IS 'Computed field: oid';
COMMENT ON COLUMN mca_env_base.pg_type.typname IS 'Computed field: typname';
COMMENT ON COLUMN mca_env_base.pg_type.typnamespace IS 'Computed field: typnamespace';
COMMENT ON COLUMN mca_env_base.pg_type.typowner IS 'Computed field: typowner';
COMMENT ON COLUMN mca_env_base.pg_type.typlen IS 'Computed field: typlen';
COMMENT ON COLUMN mca_env_base.pg_type.typbyval IS 'Computed field: typbyval';
COMMENT ON COLUMN mca_env_base.pg_type.typtype IS 'Computed field: typtype';
COMMENT ON COLUMN mca_env_base.pg_type.typcategory IS 'Computed field: typcategory';
COMMENT ON COLUMN mca_env_base.pg_type.typispreferred IS 'Computed field: typispreferred';
COMMENT ON COLUMN mca_env_base.pg_type.typisdefined IS 'Computed field: typisdefined';
COMMENT ON COLUMN mca_env_base.pg_type.typdelim IS 'Computed field: typdelim';
COMMENT ON COLUMN mca_env_base.pg_type.typrelid IS 'Computed field: typrelid';
COMMENT ON COLUMN mca_env_base.pg_type.typsubscript IS 'Computed field: typsubscript';
COMMENT ON COLUMN mca_env_base.pg_type.typelem IS 'Computed field: typelem';
COMMENT ON COLUMN mca_env_base.pg_type.typarray IS 'Computed field: typarray';
COMMENT ON COLUMN mca_env_base.pg_type.typinput IS 'Computed field: typinput';
COMMENT ON COLUMN mca_env_base.pg_type.typoutput IS 'Computed field: typoutput';
COMMENT ON COLUMN mca_env_base.pg_type.typreceive IS 'Computed field: typreceive';
COMMENT ON COLUMN mca_env_base.pg_type.typsend IS 'Computed field: typsend';
COMMENT ON COLUMN mca_env_base.pg_type.typmodin IS 'Computed field: typmodin';
COMMENT ON COLUMN mca_env_base.pg_type.typmodout IS 'Computed field: typmodout';
COMMENT ON COLUMN mca_env_base.pg_type.typanalyze IS 'Computed field: typanalyze';
COMMENT ON COLUMN mca_env_base.pg_type.typalign IS 'Computed field: typalign';
COMMENT ON COLUMN mca_env_base.pg_type.typstorage IS 'Computed field: typstorage';
COMMENT ON COLUMN mca_env_base.pg_type.typnotnull IS 'Computed field: typnotnull';
COMMENT ON COLUMN mca_env_base.pg_type.typbasetype IS 'Computed field: typbasetype';
COMMENT ON COLUMN mca_env_base.pg_type.typtypmod IS 'Computed field: typtypmod';
COMMENT ON COLUMN mca_env_base.pg_type.typndims IS 'Computed field: typndims';
COMMENT ON COLUMN mca_env_base.pg_type.typcollation IS 'Computed field: typcollation';
COMMENT ON COLUMN mca_env_base.pg_type.typdefaultbin IS 'Computed field: typdefaultbin';
COMMENT ON COLUMN mca_env_base.pg_type.typdefault IS 'Computed field: typdefault';
COMMENT ON COLUMN mca_env_base.pg_type.typacl IS 'Computed field: typacl';

-- View: pg_views
COMMENT ON TABLE mca_env_base.pg_views IS 'View based on duckdb_views';
COMMENT ON COLUMN mca_env_base.pg_views.schemaname IS 'Schemaname';
COMMENT ON COLUMN mca_env_base.pg_views.viewname IS 'Viewname';
COMMENT ON COLUMN mca_env_base.pg_views.viewowner IS 'Viewowner';
COMMENT ON COLUMN mca_env_base.pg_views.definition IS 'Definition';

-- View: pragma_database_list
COMMENT ON TABLE mca_env_base.pragma_database_list IS 'View based on duckdb_databases';
COMMENT ON COLUMN mca_env_base.pragma_database_list.seq IS 'Seq';
COMMENT ON COLUMN mca_env_base.pragma_database_list.name IS 'Name';
COMMENT ON COLUMN mca_env_base.pragma_database_list.file IS 'File';

-- View: referential_constraints
COMMENT ON TABLE mca_env_base.referential_constraints IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.referential_constraints.constraint_catalog IS 'Constraint catalog';
COMMENT ON COLUMN mca_env_base.referential_constraints.constraint_schema IS 'Constraint schema';
COMMENT ON COLUMN mca_env_base.referential_constraints.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.referential_constraints.unique_constraint_catalog IS 'Unique constraint catalog';
COMMENT ON COLUMN mca_env_base.referential_constraints.unique_constraint_schema IS 'Unique constraint schema';
COMMENT ON COLUMN mca_env_base.referential_constraints.unique_constraint_name IS 'Unique constraint name';
COMMENT ON COLUMN mca_env_base.referential_constraints.match_option IS 'Match option';
COMMENT ON COLUMN mca_env_base.referential_constraints.update_rule IS 'Update rule';
COMMENT ON COLUMN mca_env_base.referential_constraints.delete_rule IS 'Delete rule';

-- View: schemata
COMMENT ON TABLE mca_env_base.schemata IS 'View based on duckdb_schemas';
COMMENT ON COLUMN mca_env_base.schemata.catalog_name IS 'Catalog name';
COMMENT ON COLUMN mca_env_base.schemata.schema_name IS 'Schema name';
COMMENT ON COLUMN mca_env_base.schemata.schema_owner IS 'Schema owner';
COMMENT ON COLUMN mca_env_base.schemata.default_character_set_catalog IS 'Computed field: default_character_set_catalog';
COMMENT ON COLUMN mca_env_base.schemata.default_character_set_schema IS 'Computed field: default_character_set_schema';
COMMENT ON COLUMN mca_env_base.schemata.default_character_set_name IS 'Computed field: default_character_set_name';
COMMENT ON COLUMN mca_env_base.schemata.sql_path IS 'Computed field: sql_path';

-- View: sqlite_master
COMMENT ON TABLE mca_env_base.sqlite_master IS 'View based on duckdb_tables, duckdb_views, duckdb_indexes';
COMMENT ON COLUMN mca_env_base.sqlite_master.type IS 'Type';
COMMENT ON COLUMN mca_env_base.sqlite_master.name IS 'Name';
COMMENT ON COLUMN mca_env_base.sqlite_master.tbl_name IS 'Tbl name';
COMMENT ON COLUMN mca_env_base.sqlite_master.rootpage IS 'Rootpage';
COMMENT ON COLUMN mca_env_base.sqlite_master.sql IS 'Sql';

-- View: sqlite_schema
COMMENT ON TABLE mca_env_base.sqlite_schema IS 'View based on sqlite_master;';
COMMENT ON COLUMN mca_env_base.sqlite_schema.type IS 'Type';
COMMENT ON COLUMN mca_env_base.sqlite_schema.name IS 'Name';
COMMENT ON COLUMN mca_env_base.sqlite_schema.tbl_name IS 'Tbl name';
COMMENT ON COLUMN mca_env_base.sqlite_schema.rootpage IS 'Rootpage';
COMMENT ON COLUMN mca_env_base.sqlite_schema.sql IS 'Sql';

-- View: sqlite_temp_master
COMMENT ON TABLE mca_env_base.sqlite_temp_master IS 'View based on sqlite_master;';
COMMENT ON COLUMN mca_env_base.sqlite_temp_master.type IS 'Type';
COMMENT ON COLUMN mca_env_base.sqlite_temp_master.name IS 'Name';
COMMENT ON COLUMN mca_env_base.sqlite_temp_master.tbl_name IS 'Tbl name';
COMMENT ON COLUMN mca_env_base.sqlite_temp_master.rootpage IS 'Rootpage';
COMMENT ON COLUMN mca_env_base.sqlite_temp_master.sql IS 'Sql';

-- View: sqlite_temp_schema
COMMENT ON TABLE mca_env_base.sqlite_temp_schema IS 'View based on sqlite_master;';
COMMENT ON COLUMN mca_env_base.sqlite_temp_schema.type IS 'Type';
COMMENT ON COLUMN mca_env_base.sqlite_temp_schema.name IS 'Name';
COMMENT ON COLUMN mca_env_base.sqlite_temp_schema.tbl_name IS 'Tbl name';
COMMENT ON COLUMN mca_env_base.sqlite_temp_schema.rootpage IS 'Rootpage';
COMMENT ON COLUMN mca_env_base.sqlite_temp_schema.sql IS 'Sql';

-- View: table_constraints
COMMENT ON TABLE mca_env_base.table_constraints IS 'View based on duckdb_constraints';
COMMENT ON COLUMN mca_env_base.table_constraints.constraint_catalog IS 'Constraint catalog';
COMMENT ON COLUMN mca_env_base.table_constraints.constraint_schema IS 'Constraint schema';
COMMENT ON COLUMN mca_env_base.table_constraints.constraint_name IS 'Constraint name';
COMMENT ON COLUMN mca_env_base.table_constraints.table_catalog IS 'Table catalog';
COMMENT ON COLUMN mca_env_base.table_constraints.table_schema IS 'Table schema';
COMMENT ON COLUMN mca_env_base.table_constraints.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.table_constraints.constraint_type IS 'Computed field: constraint_type';
COMMENT ON COLUMN mca_env_base.table_constraints.is_deferrable IS 'Computed field: is_deferrable';
COMMENT ON COLUMN mca_env_base.table_constraints.initially_deferred IS 'Computed field: initially_deferred';
COMMENT ON COLUMN mca_env_base.table_constraints.enforced IS 'Computed field: enforced';
COMMENT ON COLUMN mca_env_base.table_constraints.nulls_distinct IS 'Computed field: nulls_distinct';

-- View: tables
COMMENT ON TABLE mca_env_base.tables IS 'View based on duckdb_tables, duckdb_views';
COMMENT ON COLUMN mca_env_base.tables.table_catalog IS 'Computed field: table_catalog';
COMMENT ON COLUMN mca_env_base.tables.table_schema IS 'Computed field: table_schema';
COMMENT ON COLUMN mca_env_base.tables.table_name IS 'Computed field: table_name';
COMMENT ON COLUMN mca_env_base.tables.table_type IS 'Computed field: table_type';
COMMENT ON COLUMN mca_env_base.tables.self_referencing_column_name IS 'Computed field: self_referencing_column_name';
COMMENT ON COLUMN mca_env_base.tables.reference_generation IS 'Computed field: reference_generation';
COMMENT ON COLUMN mca_env_base.tables.user_defined_type_catalog IS 'Computed field: user_defined_type_catalog';
COMMENT ON COLUMN mca_env_base.tables.user_defined_type_schema IS 'Computed field: user_defined_type_schema';
COMMENT ON COLUMN mca_env_base.tables.user_defined_type_name IS 'Computed field: user_defined_type_name';
COMMENT ON COLUMN mca_env_base.tables.is_insertable_into IS 'Computed field: is_insertable_into';
COMMENT ON COLUMN mca_env_base.tables.is_typed IS 'Computed field: is_typed';
COMMENT ON COLUMN mca_env_base.tables.commit_action IS 'Computed field: commit_action';
COMMENT ON COLUMN mca_env_base.tables.TABLE_COMMENT IS 'Computed field: TABLE_COMMENT';

-- View: views
COMMENT ON TABLE mca_env_base.views IS 'View based on duckdb_views';
COMMENT ON COLUMN mca_env_base.views.table_catalog IS 'Table catalog';
COMMENT ON COLUMN mca_env_base.views.table_schema IS 'Table schema';
COMMENT ON COLUMN mca_env_base.views.table_name IS 'Table name';
COMMENT ON COLUMN mca_env_base.views.view_definition IS 'View definition';
COMMENT ON COLUMN mca_env_base.views.check_option IS 'Check option';
COMMENT ON COLUMN mca_env_base.views.is_updatable IS 'Is updatable';
COMMENT ON COLUMN mca_env_base.views.is_insertable_into IS 'Is insertable into';
COMMENT ON COLUMN mca_env_base.views.is_trigger_updatable IS 'Is trigger updatable';
COMMENT ON COLUMN mca_env_base.views.is_trigger_deletable IS 'Is trigger deletable';
COMMENT ON COLUMN mca_env_base.views.is_trigger_insertable_into IS 'Is trigger insertable into';

-- View: weca_lep_la_vw
COMMENT ON TABLE mca_env_base.weca_lep_la_vw IS 'View based on ca_la_lookup_inc_ns_vw';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.ladcd IS 'Ladcd';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.ladnm IS 'Ladnm';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.cauthcd IS 'Cauthcd';
COMMENT ON COLUMN mca_env_base.weca_lep_la_vw.cauthnm IS 'Cauthnm';
