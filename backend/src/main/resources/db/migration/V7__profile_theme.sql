-- Tema visual escolhido pelo usuário (neon_orange, cyber_red, ...).
-- Aditivo e opcional: o app aplica o tema salvo localmente na hora e usa este
-- campo apenas para a preferência acompanhar a conta em outro dispositivo.
ALTER TABLE profiles ADD COLUMN theme VARCHAR(40);
