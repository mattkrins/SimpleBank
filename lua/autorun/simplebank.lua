if SERVER then include "simplebank/init.lua" else include "simplebank/cl_init.lua" end
AddCSLuaFile("simplebank/sh_init.lua")
local SimpleBank = include ("simplebank/sh_init.lua")
assert(SimpleBank, "Simplebank failed to load.")
if !SimpleBank then return false end

// Add any custom languages below this line following the convention below (converted phrases will automaticly capitalised):
// SimpleBank:AddLanguage(phrase [string], convertedPhrase [string], language [string])

// Pirate-English Yarg!
SimpleBank:AddLanguage("cancel", "avast", "en-PT")
SimpleBank:AddLanguage("deposit", "stash", "en-PT")
SimpleBank:AddLanguage("deposited", "stashed", "en-PT")
SimpleBank:AddLanguage("withdraw", "grab", "en-PT")
SimpleBank:AddLanguage("withdrew", "grabbed", "en-PT")
SimpleBank:AddLanguage("transfer", "ship to", "en-PT")
SimpleBank:AddLanguage("transferred", "shipped to", "en-PT")
SimpleBank:AddLanguage("account", "treasure", "en-PT")
SimpleBank:AddLanguage("cash", "doubloons", "en-PT")
SimpleBank:AddLanguage("balance", "booty", "en-PT")
SimpleBank:AddLanguage("atm", "trove", "en-PT")
SimpleBank:AddLanguage("bank", "treasure", "en-PT")
SimpleBank:AddLanguage("slogan", "Safely stash ye harrrd earned treasure!", "en-PT")
SimpleBank:AddLanguage("confirm_amount", "inspect treasure before shipping", "en-PT")
SimpleBank:AddLanguage("transfer_alert", "grab shipping notices from other pirates", "en-PT")
SimpleBank:AddLanguage("player", "pirate", "en-PT")
SimpleBank:AddLanguage("doesnt_exist", "not aboard!", "en-PT")
SimpleBank:AddLanguage("cant_afford", "yea cant haggle that!", "en-PT")
