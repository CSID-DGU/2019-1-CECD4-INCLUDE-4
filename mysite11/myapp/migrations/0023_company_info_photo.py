# Generated by Django 2.2.5 on 2019-11-23 05:41

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0022_auto_20191118_1653'),
    ]

    operations = [
        migrations.AddField(
            model_name='company_info',
            name='photo',
            field=models.ImageField(null=True, upload_to='image'),
        ),
    ]