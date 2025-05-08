Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Form Tasarımı
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Active Directory Kullanıcı Bilgisi"
$Form.Size = New-Object System.Drawing.Size(500, 550)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Kullanıcı Adı Etiketi
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Kullanıcı Adı:"
$Label.Location = New-Object System.Drawing.Point(20, 20)
$Label.AutoSize = $true
$Form.Controls.Add($Label)

# Kullanıcı Adı İçin TextBox
$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Location = New-Object System.Drawing.Point(120, 18)
$TextBox.Width = 200
$Form.Controls.Add($TextBox)

# Kullanıcı Fotoğrafı
$PictureBox = New-Object System.Windows.Forms.PictureBox
$PictureBox.Location = New-Object System.Drawing.Point(350, 20)
$PictureBox.Size = New-Object System.Drawing.Size(100, 100)
$PictureBox.BorderStyle = "FixedSingle"
$PictureBox.SizeMode = "StretchImage"
$Form.Controls.Add($PictureBox)

# Kullanıcı Bilgilerini Gösteren ListBox
$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Point(20, 130)
$ListBox.Size = New-Object System.Drawing.Size(450, 300)
$ListBox.SelectionMode = "MultiExtended"
$ListBox.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip
$CopyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyMenuItem.Text = "Kopyala"
$CopyMenuItem.Add_Click({
    $SelectedItems = $ListBox.SelectedItems | ForEach-Object { $_ }
    if ($SelectedItems) {
        [System.Windows.Forms.Clipboard]::SetText($SelectedItems -join "`r`n")
    }
})
$ListBox.ContextMenuStrip.Items.Add($CopyMenuItem)
$Form.Controls.Add($ListBox)

# Bilgileri Getir Butonu
$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Sorgula"
$Button.Location = New-Object System.Drawing.Point(120, 50)
$Button.BackColor = [System.Drawing.Color]::FromArgb(50, 150, 250)
$Button.ForeColor = [System.Drawing.Color]::White
$Button.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)

$Button.Add_Click({
    $Username = $TextBox.Text
    if ($Username -ne "") {
        Try {
            # Active Directory'den Kullanıcı Bilgilerini Çek
            $User = Get-ADUser -Identity $Username -Properties *

            # Listeyi Temizle
            $ListBox.Items.Clear()
            
            # Kullanıcı Bilgilerini Listeye Ekle (İkonlarla)
            $ListBox.Items.Add("👤 Adı Soyadı: $($User.DisplayName)")
            $ListBox.Items.Add("📧 E-Posta: $($User.Mail)")
            $ListBox.Items.Add("📞 Telefon: $($User.TelephoneNumber)")
            $ListBox.Items.Add("🏢 Departman: $($User.Department)")
            $ListBox.Items.Add("🔑 Oturum Açma Adı: $($User.SamAccountName)")
            $ListBox.Items.Add("⏰ Son Giriş Tarihi: $($User.LastLogonDate)")
            $ListBox.Items.Add("✅ Hesap Durumu: $(if($User.Enabled){"Aktif"}else{"Devre Dışı"})")
            
            # Parola Bilgileri
            $PasswordNeverExpires = if ($User.PasswordNeverExpires) { "Evet" } else { "Hayır" }
            $PwdLastSet = $User.PasswordLastSet
            if ($PwdLastSet) {
                $MaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
                $DaysUntilPasswordExpires = $MaxPasswordAge - (New-TimeSpan -Start $PwdLastSet -End (Get-Date)).Days
                $ListBox.Items.Add("⏳ Parola Değiştirme Kalan Gün: $DaysUntilPasswordExpires")
            }
            $ListBox.Items.Add("🔒 Parola Süresiz mi?: $PasswordNeverExpires")
            
            # Hesap Süre Sonu Bilgisi
            $AccountExpires = $User.AccountExpires
            if ($AccountExpires -eq 0 -or $AccountExpires -eq 9223372036854775807) {
                $ListBox.Items.Add("⏲️ Hesap Süre Sona Erme Zamanı: Sona Ermez :)")
            } else {
                $ExpireDate = [DateTime]::FromFileTime($AccountExpires)
                $ListBox.Items.Add("⏲️ Hesap Süre Sona Erme Zamanı: Sona Erer:( , $ExpireDate")
            }
            
            # Manager Bilgisi
            if ($User.Manager) {
                $Manager = Get-ADUser -Identity $User.Manager -Properties DisplayName
                $ListBox.Items.Add("👥 Yöneticisi: $($Manager.DisplayName)")
            }
            
            # OU Bilgisi (En alta)
            $ListBox.Items.Add("📂 OU Bilgisi: $($User.DistinguishedName)")
            
            # Grup Üyelikleri (En alta)
            $Groups = Get-ADUser -Identity $Username -Properties MemberOf | Select-Object SiaObject -ExpandProperty MemberOf
            if ($Groups) {
                $ListBox.Items.Add("👥 Grup Üyelikleri:")
                $Groups | ForEach-Object { $ListBox.Items.Add(" - $_") }
            }
            
            # Kullanıcı Fotoğrafı
            if ($User.thumbnailPhoto -ne $null) {
                $ImageData = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new($User.thumbnailPhoto))
                $PictureBox.Image = $ImageData
            } else {
                $PictureBox.Image = $null
            }

        } Catch {
            [System.Windows.Forms.MessageBox]::Show("Kullanıcı bulunamadı!", "Hata", "OK", "Error")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Lütfen bir kullanıcı adı girin!", "Uyarı", "OK", "Warning")
    }
})
$Form.Controls.Add($Button)

# Sürüm ve Web Sitesi Bilgisi
$VersionLabel = New-Object System.Windows.Forms.Label
$VersionLabel.Text = "BEROVSKI GURURLA SUNAR"
$VersionLabel.Location = New-Object System.Drawing.Point(20, 450)
$VersionLabel.AutoSize = $true
$VersionLabel.ForeColor = [System.Drawing.Color]::Gray
$Form.Controls.Add($VersionLabel)

# Formu Göster
$Form.ShowDialog()