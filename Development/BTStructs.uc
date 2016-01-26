class BTStructs extends Object;

struct sPlayerReference
{
    var PlayerController player;
    var int playerSlot;
};

struct sConfigProperty
{
    var Property Property;
    var localized string Category;
    var localized string Description;
    var localized string Hint;
    var byte AccessLevel;
    var byte Weight;

    /** If Type is *empty* then the type will be guessed from the Property.Class variable. */
    var string Type;

    /** "DEFAULT;MIN:MAX" */
    var string Rules;
    var string Privileges;
    var bool bMultiPlayerOnly;
    var bool bAdvanced;
};