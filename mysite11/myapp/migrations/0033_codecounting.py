# Generated by Django 2.2.4 on 2019-11-24 05:49

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0032_tokensell_sell_code'),
    ]

    operations = [
        migrations.CreateModel(
            name='codecounting',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('tokensellcount', models.IntegerField(default=0)),
                ('requestcount', models.IntegerField(default=0)),
            ],
        ),
    ]
