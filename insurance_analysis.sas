/* --------------------------------------------------
   1. CAS environment setup
-------------------------------------------------- */
cas casauto;
caslib _all_ assign;

libname set "/export/viya/homes/21030411038@aybu.edu.tr/sasuser.viya/data/kaggle";


/* --------------------------------------------------
   2. Import dataset (CSV → SAS)
-------------------------------------------------- */
proc import datafile="/export/viya/homes/21030411038@aybu.edu.tr/sasuser.viya/data/kaggle/insurance.csv"
    dbms=csv
    out=set.insurance
    replace;
run;


/* --------------------------------------------------
   3. Data exploration
-------------------------------------------------- */

/* Dataset structure */
proc contents data=set.insurance;
run;

/* Missing values (numeric variables) */
proc means data=set.insurance n nmiss;
run;

/* Missing values (categorical variables) */
proc freq data=set.insurance;
    tables sex smoker region / missing;
run;

/* Quick preview */
proc print data=set.insurance (obs=10);
run;

/* Frequency distribution */
proc freq data=set.insurance;
    tables region;
run;


/* --------------------------------------------------
   4. Data transformation
-------------------------------------------------- */

data set.insurance;
    set set.insurance;

    /* Gender transformation */
    if sex = 'male' then gender = 'M';
    else if sex = 'female' then gender = 'F';

    /* Region uppercase */
    region_upper = upcase(region);
run;


/* --------------------------------------------------
   5. Feature engineering (business rules)
-------------------------------------------------- */

proc sql;
    create table set.insurance_processed as
    select *,
        charges format=dollar12.2,

        /* Age segmentation */
        case
            when age <= 25 then 'Young'
            when 26 <= age <= 40 then 'Middle Age'
            when age > 40 then 'Senior'
        end as age_group,

        /* Charges segmentation */
        case
            when charges < 5000 then 'Low'
            when charges < 10000 then 'Medium'
            else 'High'
        end as charges_group,

        /* BMI categorization */
        case
            when bmi < 18.5 then 'Underweight'
            when bmi < 25 then 'Normal'
            when bmi < 30 then 'Overweight'
            when bmi < 35 then 'Obese Class I'
            when bmi < 45 then 'Obese Class II'
            else 'Obese Class III'
        end as bmi_group,

        /* Region simplification */
        case
            when region like '%north%' then 'North'
            when region like '%south%' then 'South'
            else 'Other'
        end as region_group

    from set.insurance;
quit;


/* --------------------------------------------------
   6. Save dataset to CAS
-------------------------------------------------- */
proc casutil;
    save casdata="insurance_processed"
         casout="insurance_processed.sashdat"
         outcaslib="casuser"
         compress
         replace;
quit;
