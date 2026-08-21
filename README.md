# Проект **Тестовое приложение с кеширующим слоем**

### **Задача**
Необходимо развернуть тестовое приложение с кеширующим слоем.
Оно состоит из четырёх основных компонентов:
**1.** **База** **данных** **PostgreSQL**
**2. Backend API** **на** **Go**
**3. Redis**
**4. Прокси-приложение на Python (Flask)**

### **Логика работы**
Внешние пользователи обращаются в **прокси**. Прокси проверяет  наличие запрашиваемых данных в **Redis**.
- Если данные найдены – сразу возвращает их клиенту.
- Если данных нет – прокси запрашивает их у **Backend API,** которое  ходит в **PostgreSQL** и возвращает результат. Прокси сохраняет данные  в Redis и отдаёт клиенту.
### **Репозиторий**
https://github.com/alenka-byte/project

### **Результаты**

1.    backend-api.service — **active (running)**.
![[Pasted image 20260821184948.png]]
2.    proxy-api.service — **active (running)**.
![[Pasted image 20260821185007.png]]
3.    PostgreSQL + SELECT COUNT(*) → **20**.
![[Pasted image 20260821185021.png]]
![[Pasted image 20260821185015.png]]
4.    Valkey → PONG.![[Pasted image 20260821185030.png]]
![[Pasted image 20260821185044.png]]

5.    Backend curl /user?id=5 → данные Charlie Davis.
![[Pasted image 20260821185127.png]]
6.    Proxy два curl подряд → cached=false **и** cached=true.
![[Pasted image 20260821185136.png]]
7.    iptables → разрешение Proxy → Backend.
![[Pasted image 20260821185222.png]]

![[Pasted image 20260821185231.png]]

